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
    func setProject(with project: ProjectSetDTO, id: Int, by userId: String, at setDate: Date) throws {
        // Create Entity
        setEntity(with: ProjectObject(from: project, id: id, userId: userId, at: setDate))
        // Set Entity
        try context.save()
    }
    
    //--------------------
    // Get
    //--------------------
    // Object
    func getProject(from projectId: Int, and userId: String) throws -> ProjectObject {
        // Fetch Entity
        let entity = try fetchEntity(with: projectId, and: userId)
        // Convert & Return
        return try convertToObject(with: entity)
    }
    // DTO
    func getProjectCards(by userId: String) throws -> [ProjectCardDTO] {
        // Fetch Entities
        let entities = try fetchEntities(with: userId)
        // Convert & Return
        return try entities.map { try convertToDTO(with: $0) }
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
        // convert & return
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
        // fetch & return
        return try context.fetch(fetchReq)
    }
    //----------------------------------------------
    
    // Update Check
    private func checkUpdate(from origin: ProjectEntity, to updated: ProjectUpdateDTO) -> Bool {
        var isUpdated = false

        if let newTitle = updated.newTitle {
            isUpdated = util.updateFieldIfNeeded(&origin.proj_title, newValue: newTitle) || isUpdated
        }
        if let newStatus = updated.newStatus {
            isUpdated = util.updateFieldIfNeeded(&origin.proj_finished, newValue: newStatus) || isUpdated
        }
        if let newDeadline = updated.newDeadline {
            isUpdated = util.updateFieldIfNeeded(&origin.proj_deadline, newValue: newDeadline) || isUpdated
        }
        if let newTodoRegist = updated.newTodoRegist {
            isUpdated = util.updateFieldIfNeeded(&origin.proj_todo_registed, newValue: Int32(newTodoRegist)) || isUpdated
        }
        if let newTodoFinish = updated.newTodoFinish {
            isUpdated = util.updateFieldIfNeeded(&origin.proj_todo_finished, newValue: Int32(newTodoFinish)) || isUpdated
        }

        return isUpdated
    }
    //----------------------------------------------
    
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
    //----------------------------------------------
    
    // Convert: to Object
    private func convertToObject(with entity: ProjectEntity) throws -> ProjectObject {
        guard let object = ProjectObject(entity: entity) else {
            throw ProjectErrorCD.UnexpectedObjectConvertError
        }
        return object
    }
    
    // Convert: to Card
    private func convertToDTO(with entity: ProjectEntity) throws -> ProjectCardDTO {
        guard let dto = ProjectCardDTO(entity: entity) else {
            throw ProjectErrorCD.UnexpectedDTOConvertError
        }
        return dto
    }
}

//===============================
// MARK: - Exception
//===============================
enum ProjectErrorCD: LocalizedError {
    case ProjectRetrievalByIdentifierFailed
    case UnexpectedObjectConvertError
    case UnexpectedDTOConvertError
    
    var errorDescription: String?{
        switch self {
        case .ProjectRetrievalByIdentifierFailed:
            return "Coredata: Unable to retrieve 'Project' data using the provided identifier."
        case .UnexpectedObjectConvertError:
            return "Coredata: There was an unexpected error while Convert 'Project' Entity to Object"
        case .UnexpectedDTOConvertError:
            return "Coredata: There was an unexpected error while Convert 'Project' Entity to DTO"
        }
    }
}
