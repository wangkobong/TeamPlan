//
//  TodoServiceCoredata.swift
//  teamplan
//
//  Created by 주찬혁 on 1/3/24.
//  Copyright © 2024 team1os. All rights reserved.
//

import Foundation
import CoreData

//MARK: Main

final class TodoServiceCoredata {
    typealias Entity = TodoEntity
    typealias Object = TodoObject
    typealias DTO = TodoUpdateDTO

    // shared
    var object = TodoObject()
    var objectList = [TodoObject]()
    
    func setObject(context: NSManagedObjectContext, with object: TodoObject) throws -> Bool {
        let todoEntity = TodoEntity(context: context)
        let projectEntity = try getProjectEntity(
            context: context, userId: object.userId, projectId: object.projectId
        )
        createEntity(with: todoEntity, and: projectEntity, object: object)
        return checkEntity(with: todoEntity)
    }
    
    func getObject(context: NSManagedObjectContext, userId: String, projectId: Int, todoId: Int) throws -> Bool {
        let entity = try getEntity(context: context, userId: userId, projectId: projectId, todoId: todoId)
        return convertToObject(with: entity)
    }
    
    func getObjectList(context: NSManagedObjectContext, userId: String, projectId: Int) throws -> Bool {
        let entities = try getEntities(context: context, userId: userId, projectId: projectId)
        return convertToObjects(with: entities)
    }
    
    func updateObject(context: NSManagedObjectContext, updated: DTO) throws -> Bool {
        let entity = try getEntity(context: context, userId: updated.userId, projectId: updated.projectId, todoId: updated.todoId)
        return checkupdate(from: entity, to: updated)
    }
    
    func deleteObjectList(context: NSManagedObjectContext, userId: String, projectId: Int) throws -> Bool {
        let entities = try getEntities(context: context, userId: userId, projectId: projectId)
        
        if entities.isEmpty {
            print("[Coredata-Todo] There is no todo to delete")
            return true
        }
        
        for entity in entities {
            context.delete(entity)
        }
        return true
    }
}

//MARK: Context Related

extension TodoServiceCoredata{
    
    // Set
    private func createEntity(with todoEntity: TodoEntity, and projectEntity: ProjectEntity, object: TodoObject) {
        
        todoEntity.project_relationship = projectEntity
        todoEntity.todo_id = Int32(object.todoId)
        todoEntity.project_id = Int32(object.projectId)
        todoEntity.user_id = object.userId
        todoEntity.desc = object.desc
        todoEntity.pinned = object.pinned
        todoEntity.status = Int32(object.status.rawValue)
    }
    
    private func checkEntity(with entity: TodoEntity) -> Bool {
        if entity.project_relationship == nil {
            print("[TodoRepo] nil detected: 'project_relationship'")
            return false
        }
        if entity.user_id == nil {
            print("[TodoRepo] nil detected: 'user_id'")
            return false
        }
        if entity.desc == nil {
            print("[TodoRepo] nil detected: 'desc'")
            return false
        }
        return true
    }
    
    // Fetch: Project Entity
    private func getProjectEntity(context: NSManagedObjectContext, userId: String, projectId: Int) throws -> ProjectEntity {
        let fetchReq: NSFetchRequest<ProjectEntity> = ProjectEntity.fetchRequest()
        fetchReq.predicate = NSPredicate(format: EntityPredicate.project.format, userId, projectId)
        fetchReq.fetchLimit = 1
        
        guard let entity = try context.fetch(fetchReq).first else {
            throw CoredataError.fetchFailure(serviceName: .cd, dataType: .project)
        }
        return entity
    }
    
    // Fetch: Multi Todo
    private func getEntities(context: NSManagedObjectContext, userId: String, projectId: Int) throws -> [Entity] {
        let projectEntity = try getProjectEntity(
            context: context,
            userId: userId,
            projectId: projectId
        )
        guard let todoEntities = projectEntity.todo_relationship as? Set<Entity> else {
            throw CoredataError.fetchFailure(serviceName: .cd, dataType: .todo)
        }
        return Array(todoEntities)
    }
    
    // Fetch: Single Todo
    private func getEntity(context: NSManagedObjectContext, userId: String, projectId: Int, todoId: Int) throws -> TodoEntity {
        guard let entity = try getEntities(
            context: context,
            userId: userId,
            projectId: projectId
        ).first(where: { $0.todo_id == todoId }) else {
            throw CoredataError.searchFailure(serviceName: .cd, dataType: .todo)
        }
        return entity
    }
}

//MARK: Util

extension TodoServiceCoredata{
    
    // Converter: to Object
    private func convertToObject(with entity: TodoEntity) -> Bool {
        guard let userId = entity.user_id,
              let desc = entity.desc,
              let status = TodoStatus(rawValue: Int(entity.status)) 
        else {
            print("[Coredata-Todo] Failed to fetch entity data")
            return false
        }
        self.object = TodoObject(
            projectId: Int(entity.project_id),
            todoId: Int(entity.todo_id),
            userId: userId,
            desc: desc,
            pinned: entity.pinned,
            status: status
        )
        return true
    }
    
    private func convertToObjects(with entities: [Entity]) -> Bool {
        self.objectList = []
        for entity in entities {
            if convertToObject(with: entity) {
                self.objectList.append(self.object)
            } else {
                print("[Coredata-Todo] Failed to convert entity to object")
                return false
            }
        }
        return true
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

//MARK: DTO

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
