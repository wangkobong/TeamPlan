//
//  ProjectServicesCoredata.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/08/25.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation
import CoreData

final class ProjectServicesCoredata{
    
    //================================
    // MARK: - CoreData Setting
    //================================
    let util = Utilities()
    let cd = CoreDataManager.shared
    var context: NSManagedObjectContext {
        return cd.context
    }
    
    //================================
    // MARK: - Set Project
    //================================
    func setProject(from project: ProjectSetDTO, at id: Int, by userId: String) throws {
        
        // Create Entity & Set Data
        setProjectentity(reqProject: ProjectObject(from: project, id: id, userId: userId))
        try context.save()
    }
    // Support Function
    private func setProjectentity(reqProject: ProjectObject){
        let entity = ProjectEntity(context: context)
        
        entity.proj_id = Int32(reqProject.proj_id)
        entity.proj_user_id = reqProject.proj_user_id
        entity.proj_title = reqProject.proj_title
        entity.proj_started_at = reqProject.proj_started_at
        entity.proj_deadline = reqProject.proj_deadline
        entity.proj_finished = reqProject.proj_finished
        entity.proj_registed_at = reqProject.proj_registed_at
        entity.proj_changed_at = reqProject.proj_changed_at
        entity.proj_finished_at = reqProject.proj_finished_at
    }
    
    //================================
    // MARK: - Get Project
    //================================
    // Get Single Project
    func getProject(from projectId: Int) throws -> ProjectObject {
        
        // parameter setting
        let fetchReq: NSFetchRequest<ProjectEntity> = ProjectEntity.fetchRequest()
        
        // Request Query
        fetchReq.predicate = NSPredicate(format: "proj_id == %@", projectId)
        fetchReq.fetchLimit = 1
        
        // Search Data
        guard let reqProject = try context.fetch(fetchReq).first else {
            throw ProjectErrorCD.ProjectRetrievalByIdentifierFailed
        }
        // Convert to Object & Get
        guard let projectData = ProjectObject(entity: reqProject) else {
            throw ProjectErrorCD.UnexpectedConvertError
        }
        return projectData
    }
    
    // Get ProjectCards
    func getProjectCards(by userId: String) throws -> [ProjectCardDTO] {
        
        // parameter setting
        let fetchReq: NSFetchRequest<ProjectEntity> = ProjectEntity.fetchRequest()
        
        // Request Query
        fetchReq.predicate = NSPredicate(format: "proj_user_id == %@", userId)
        
        // Convert to Object & Get All
        let reqProjects = try context.fetch(fetchReq)
        let projectsData = reqProjects.compactMap { ProjectCardDTO(from: $0) }
        if projectsData.count != reqProjects.count {
            throw ProjectErrorCD.UnexpectedConvertError
        }
        return projectsData
    }
    
    //================================
    // MARK: - Update Project
    //================================
    func updateProject(to updatedProject: ProjectObject) throws {
        
        // parameter setting
        let fetchReq: NSFetchRequest<ProjectEntity> = ProjectEntity.fetchRequest()
        
        // Request Query
        fetchReq.predicate = NSPredicate(format: "proj_id == %@", updatedProject.proj_id)
        fetchReq.fetchLimit = 1
        
        // Search Data
        guard let reqProject = try context.fetch(fetchReq).first else {
            throw ProjectErrorCD.ProjectRetrievalByIdentifierFailed
        }
        // Update Data
        if checkUpdate(from: reqProject, to: updatedProject){
            try context.save()
        }
    }
    // Support Function
    private func checkUpdate(from origin: ProjectEntity, to updated: ProjectObject) -> Bool {
        var isUpdated = false
        isUpdated = util.updateFieldIfNeeded(&origin.proj_title, newValue: updated.proj_title) || isUpdated
        isUpdated = util.updateFieldIfNeeded(&origin.proj_deadline, newValue: updated.proj_deadline) || isUpdated
        return isUpdated
    }
    
    
    //================================
    // MARK: - Delete Project
    //================================
    func deleteProject(_ projectId: Int) throws {
        
        // parameter setting
        let fetchReq: NSFetchRequest<ProjectEntity> = ProjectEntity.fetchRequest()
        
        // Request Query
        fetchReq.predicate = NSPredicate(format: "proj_id == %@", projectId)
        fetchReq.fetchLimit = 1
        
        // Search Data
        guard let reqProject = try context.fetch(fetchReq).first else {
            throw ProjectErrorCD.ProjectRetrievalByIdentifierFailed
        }
        // Delete Data
        context.delete(reqProject)
        try context.save()
    }
}

//===============================
// MARK: - Exception
//===============================
enum ProjectErrorCD: LocalizedError {
    case UnexpectedSetError
    case UnexpectedGetError
    case UnexpectedUpdateError
    case UnexpectedDeleteError
    case ProjectRetrievalByIdentifierFailed
    case UnexpectedFetchError
    case UnexpectedConvertError
    
    var errorDescription: String?{
        switch self {
        case .UnexpectedSetError:
            return "Coredata: There was an unexpected error while Set 'Project' details"
        case .UnexpectedGetError:
            return "Coredata: There was an unexpected error while Get 'Project' details"
        case .UnexpectedUpdateError:
            return "Coredata: There was an unexpected error while Update 'Project' details"
        case .UnexpectedDeleteError:
            return "Coredata: There was an unexpected error while Delete 'Project' details"
        case .ProjectRetrievalByIdentifierFailed:
            return "Coredata: Unable to retrieve 'Project' data using the provided identifier."
        case .UnexpectedFetchError:
            return "Coredata: There was an unexpected error while Fetch 'Project' details"
        case .UnexpectedConvertError:
            return "Coredata: There was an unexpected error while Convert 'Project' details"
        }
    }
}
