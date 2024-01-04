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
    
    //===============================
    // MARK: - Parameter
    //===============================
    let util = Utilities()
    let cm = CoreDataManager.shared
    var context: NSManagedObjectContext {
        return cm.context
    }
}

//===============================
// MARK: Main Function
//===============================
extension ProjectServicesCoredata{

    //--------------------
    // Set
    //--------------------
    func setProject(from project: ProjectSetDTO, at id: Int, by userId: String) throws {
        
        // Create Entity & Set Data
        setEntity(with: ProjectObject(from: project, id: id, userId: userId))
        try context.save()
    }
    
    //--------------------
    // Get: Object
    //--------------------
    func getProject(from projectId: Int, and userId: String) throws -> ProjectObject {
        // Fetch Entity
        let entity = try fetchEntity(with: projectId, and: userId)
        
        // Convert to Object & Get
        guard let data = ProjectObject(entity: entity) else {
            throw ProjectErrorCD.UnexpectedConvertError
        }
        return data
    }
    
    //--------------------
    // Get: Cards
    //--------------------
    func getProjectCards(by userId: String) throws -> [ProjectCardDTO] {
        // Fetch Entities
        let entities = try fetchEntities(with: userId)
        
        // Convert to Card
        let data = entities.compactMap { ProjectCardDTO(from: $0) }
        if data.count != entities.count {
            throw ProjectErrorCD.UnexpectedConvertError
        }
        return data
    }
    
    //--------------------
    // Update
    //--------------------
    func updateProject(to dto: ProjectUpdateDTO) throws {
        // Fetch Entity
        let entity = try fetchEntity(with: dto.projectId, and: dto.userId)
        
        // Update Data
        if checkUpdate(from: entity, to: dto){
            try context.save()
        }
    }
    
    //--------------------
    // Delete
    //--------------------
    func deleteProject(with projectId: Int, and userId: String) throws {
        // Fetch Entity
        let entity = try fetchEntity(with: projectId, and: userId)

        // Delete Data & Adjust
        context.delete(entity)
        try context.save()
    }
}

//===============================
// MARK: Support Function
//===============================
extension ProjectServicesCoredata{
    
    // Fetch Single Entity
    private func fetchEntity(with projectId: Int, and userId: String) throws -> ProjectEntity {
        // parameter setting
        let fetchReq: NSFetchRequest<ProjectEntity> = ProjectEntity.fetchRequest()
        
        // Request Query
        fetchReq.predicate = NSPredicate(format: "proj_id == %d AND proj_user_id == %@", projectId, userId)
        fetchReq.fetchLimit = 1
        
        guard let entity = try context.fetch(fetchReq).first else {
            throw ProjectErrorCD.ProjectRetrievalByIdentifierFailed
        }
        return entity
    }
    
    // Fetch Multiple Entity
    private func fetchEntities(with userId: String) throws -> [ProjectEntity] {
        // parameter setting
        let fetchReq: NSFetchRequest<ProjectEntity> = ProjectEntity.fetchRequest()
        
        // Request Query
        fetchReq.predicate = NSPredicate(format: "proj_user_id == %@", userId)
        
        return try context.fetch(fetchReq)
    }
    
    // Update Check
    private func checkUpdate(from origin: ProjectEntity, to updated: ProjectUpdateDTO) -> Bool {
        var isUpdated = false
        isUpdated = util.updateFieldIfNeeded(&origin.proj_title, newValue: updated.newTitle) || isUpdated
        isUpdated = util.updateFieldIfNeeded(&origin.proj_deadline, newValue: updated.newDeadline) || isUpdated
        return isUpdated
    }
    
    // Set Entity
    private func setEntity(with reqProject: ProjectObject){
        let entity = ProjectEntity(context: context)
        
        entity.proj_id = Int32(reqProject.proj_id)
        entity.proj_user_id = reqProject.proj_user_id
        entity.proj_title = reqProject.proj_title
        entity.proj_started_at = reqProject.proj_started_at
        entity.proj_deadline = reqProject.proj_deadline
        entity.proj_finished = reqProject.proj_finished
        entity.proj_todo_registed = 0
        entity.proj_todo_finished = 0
        entity.proj_registed_at = reqProject.proj_registed_at
        entity.proj_changed_at = reqProject.proj_changed_at
        entity.proj_finished_at = reqProject.proj_finished_at
    }
}

//===============================
// MARK: - Exception
//===============================
enum ProjectErrorCD: LocalizedError {
    case ProjectRetrievalByIdentifierFailed
    case UnexpectedConvertError
    
    var errorDescription: String?{
        switch self {
        case .ProjectRetrievalByIdentifierFailed:
            return "Coredata: Unable to retrieve 'Project' data using the provided identifier."
        case .UnexpectedConvertError:
            return "Coredata: There was an unexpected error while Convert 'Project' details"
        }
    }
}
