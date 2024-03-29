//
//  TodoServiceCoredata.swift
//  teamplan
//
//  Created by 주찬혁 on 1/3/24.
//  Copyright © 2024 team1os. All rights reserved.
//

import Foundation
import CoreData

final class TodoServiceCoredata: TodoObjectManage {
    typealias Entity = TodoEntity
    typealias Object = TodoObject
    typealias DTO = TodoUpdateDTO

    var context: NSManagedObjectContext
    init(coredataController: CoredataProtocol) {
        self.context = coredataController.context
    }
    
    func setObject(with object: TodoObject) throws {
        try createEntity(with: object)
        try context.save()
    }
    
    func getObject(userId: String, projectId: Int, todoId: Int) throws -> Object {
        let entity = try getEntity(userId: userId, projectId: projectId, todoId: todoId)
        return try convertToObject(with: entity)
    }
    
    func getObjects(userId: String, projectId: Int) throws -> [Object] {
        let entities = try getEntities(userId: userId, projectId: projectId)
        return try entities.map { try convertToObject(with: $0) }
    }
    
    func updateObject(updated: DTO) throws {
        let entity = try getEntity(
            userId: updated.userId, 
            projectId: updated.projectId,
            todoId: updated.todoId
        )
        if checkupdate(from: entity, to: updated) {
            try self.context.save()
        }
    }
    
    func deleteObject(userId: String, projectId: Int, todoId: Int) throws {
        let entity = try getEntity(userId: userId, projectId: projectId, todoId: todoId)
        self.context.delete(entity)
        try self.context.save()
    }
}

extension TodoServiceCoredata{
    
    // Set
    private func createEntity(with object: TodoObject) throws {
        let projectEntity = try getProjectEntity(userId: object.userId, projectId: object.projectId)
        let entity = Entity(context: context)
        
        entity.project_relationship = projectEntity
        entity.todo_id = Int32(object.todoId)
        entity.project_id = Int32(object.projectId)
        entity.user_id = object.userId
        entity.desc = object.desc
        entity.pinned = object.pinned
        entity.status = Int32(object.status.rawValue)
    }
    
    // Fetch: Project Entity
    private func getProjectEntity(userId: String, projectId: Int) throws -> ProjectEntity {
        let fetchReq: NSFetchRequest<ProjectEntity> = ProjectEntity.fetchRequest()
        fetchReq.predicate = NSPredicate(format: EntityPredicate.project.format, userId, projectId)
        fetchReq.fetchLimit = 1
        
        guard let entity = try self.context.fetch(fetchReq).first else {
            throw CoredataError.fetchFailure(serviceName: .todo)
        }
        return entity
    }
    
    // Fetch: Multi Todo
    private func getEntities(userId: String, projectId: Int) throws -> [Entity] {
        let projectEntity = try getProjectEntity(userId: userId, projectId: projectId)
        
        guard let todoEntities = projectEntity.todo_relationship as? Set<Entity> else {
            throw TodoErrorCD.UnexpectedFetchError
        }
        return Array(todoEntities)
    }
    
    // Fetch: Single Todo
    private func getEntity(userId: String, projectId: Int, todoId: Int) throws -> TodoEntity {
        guard let entity = try getEntities(userId: userId, projectId: projectId).first(where: { $0.todo_id == todoId }) else {
            throw TodoErrorCD.UnexpectedSearchError
        }
        return entity
    }
    
    // Converter: to Object
    private func convertToObject(with entity: TodoEntity) throws -> TodoObject {
        guard let userId = entity.user_id,
              let desc = entity.desc,
              let status = TodoStatus(rawValue: Int(entity.status)) else {
            throw CoredataError.convertFailure(serviceName: .todo)
        }
        return TodoObject(
            projectId: Int(entity.project_id),
            todoId: Int(entity.todo_id),
            userId: userId,
            desc: desc,
            pinned: entity.pinned,
            status: status
        )
    }
    
    // Update Check
    private func checkupdate(from entity: TodoEntity, to dto: TodoUpdateDTO) -> Bool {
        let util = Utilities()
        var isUpdated = false
        
        if let newDesc = dto.newDesc {
            isUpdated = util.updateIfNeeded(&entity.desc, newValue: newDesc) || isUpdated
        }
        if let newPinned = dto.newPinned {
            isUpdated = util.updateIfNeeded(&entity.pinned, newValue: newPinned) || isUpdated
        }
        if let newStatus = dto.newStatus {
            isUpdated = util.updateIfNeeded(&entity.status, newValue: Int32(newStatus.rawValue)) || isUpdated
        }
        return isUpdated
    }
}

struct TodoUpdateDTO{
    
    let projectId: Int
    let todoId: Int
    let userId: String
    
    var newDesc: String?
    var newStatus: TodoStatus?
    var newPinned: Bool?
    
    init(projectId: Int, todoId: Int, userId: String,
         newDesc: String? = nil,
         newStatus: TodoStatus? = nil,
         newPinned: Bool? = nil
    ){
        self.projectId = projectId
        self.todoId = todoId
        self.userId = userId
        self.newDesc = newDesc
        self.newStatus = newStatus
        self.newPinned = newPinned
    }
}


//===============================
// MARK: - Exception
//===============================
enum TodoErrorCD: LocalizedError {
    case UnexpectedFetchError
    case UnexpectedConvertError
    case UnexpectedSearchError
    case UnexpectedNilError
    
    var errorDescription: String?{
        switch self {
        case .UnexpectedFetchError:
            return "Coredata: There was an unexpected error while Fetch 'Todo' details"
        case .UnexpectedConvertError:
            return "Coredata: There was an unexpected error while Convert 'Todo' details"
        case .UnexpectedSearchError:
            return "Coredata: There was an unexpected error while Search 'Todo' details"
        case .UnexpectedNilError:
            return "Coredata: There was an unexpected Nil error while Get 'TodoId'"
        }
    }
}
