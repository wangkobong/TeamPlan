//
//  TodoServiceCoredata.swift
//  teamplan
//
//  Created by 주찬혁 on 1/3/24.
//  Copyright © 2024 team1os. All rights reserved.
//

import Foundation
import CoreData

final class TodoServiceCoredata{
    
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
extension TodoServiceCoredata{
    
    //--------------------
    // Set
    //--------------------
    func setTodo(with dto: TodoSetDTO) throws -> TodoObject {
        // Create Entity
        let newTodoEntity = createEntity(with: dto.todoDesc, and: dto.todoId)
        let projectEntity = try fetchProjectEntity(with: dto.projectId, and: dto.userId)
        // Set & Apply Change
        projectEntity.addToTodo_relationship(newTodoEntity)
        try context.save()
        // Return Object
        return try convertToObject(with: newTodoEntity)
    }
    
    //--------------------
    // Get
    //--------------------
    // TodoList
    func getTodoList(with dto: TodoRequestDTO) throws -> [TodoObject] {
        // Fetch Entity
        let entities = try fetchTodoEntities(with: dto.projectId, and: dto.userId)
        // Convert & Return
        return try entities.map { try convertToObject(with: $0) }
    }
    
    // Single Todo
    func getTodo(with dto: TodoRequestDTO) throws -> TodoObject {
        // Fetch Entity
        let entity = try fetchTodoEntity(with: dto)
        // Convert & Return
        return try convertToObject(with: entity)
    }
    
    //--------------------
    // Update
    //--------------------
    func updateTodo(with dto: TodoUpdateDTO) throws {
        // Ready to Update
        let entity = try fetchTodoEntity(
            with: TodoRequestDTO(
            projectId: dto.projectId,
            userId: dto.userId,
            todoId: dto.todoId
            )
        )
        // Update Data
        if checkupdate(from: entity, to: dto) {
            try context.save()
        }
    }
    
    //--------------------
    // Delete
    //--------------------
    func deleteTodo(with dto: TodoRequestDTO) throws {
        // Fetch Entity
        let todoEntity = try fetchTodoEntity(with: dto)
        // Delete & Apply
        context.delete(todoEntity)
        try context.save()
    }
}

//===============================
// MARK: Support Function
//===============================
extension TodoServiceCoredata{
    
    // Fetch: Project Entity
    private func fetchProjectEntity(with projectId: Int, and userId: String) throws -> ProjectEntity {
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
    
    // Fetch: Todo Entities
    private func fetchTodoEntities(with projectId: Int, and userId: String) throws -> Set<TodoEntity> {
        // fetch project entity
        let projectEntity = try fetchProjectEntity(with: projectId, and: userId)
        // fetch todo entities
        guard let todoEntities = projectEntity.todo_relationship as? Set<TodoEntity> else {
            throw TodoErrorCD.UnexpectedFetchError
        }
        return todoEntities
    }
    
    // Fetch: Single Todo
    private func fetchTodoEntity(with dto: TodoRequestDTO) throws -> TodoEntity {
        // nil check
        guard let todoId = dto.todoId else {
            throw TodoErrorCD.UnexpectedNilError
        }
        let todoEntities = try fetchTodoEntities(with: dto.projectId, and: dto.userId)
        // fetch todo
        guard let todo = todoEntities.first(where: { $0.todo_id == todoId }) else {
            throw TodoErrorCD.UnexpectedSearchError
        }
        return todo
    }
    
    // Set: Entity
    private func createEntity(with desc: String, and todoId: Int) -> TodoEntity {
        let entity = TodoEntity(context: context)
        let setDate = Date()
        
        entity.todo_id = Int32(todoId)
        entity.todo_desc = desc
        entity.todo_pinned = false
        entity.todo_status = false
        entity.todo_registed_at = setDate
        entity.todo_changed_at = setDate
        entity.todo_updated_at = setDate
        return entity
    }
    
    // Convert: to Object
    private func convertToObject(with entity: TodoEntity) throws -> TodoObject {
        guard let data = TodoObject(with: entity) else {
            throw TodoErrorCD.UnexpectedConvertError
        }
        return data
    }
    
    // Update Check
    private func checkupdate(from origin: TodoEntity, to updated: TodoUpdateDTO) -> Bool {
        var isUpdated = false
        
        if let newDesc = updated.newDesc {
            isUpdated = util.updateFieldIfNeeded(&origin.todo_desc, newValue: newDesc) || isUpdated
        }
        if let newStatus = updated.newStatus {
            isUpdated = util.updateFieldIfNeeded(&origin.todo_status, newValue: newStatus) || isUpdated
        }
        if let newPinned = updated.newPinned {
            isUpdated = util.updateFieldIfNeeded(&origin.todo_pinned, newValue: newPinned) || isUpdated
        }
        if let registedAt = updated.registedAt {
            isUpdated = util.updateFieldIfNeeded(&origin.todo_registed_at, newValue: registedAt) || isUpdated
        }
        if let changedAt = updated.changedAt {
            isUpdated = util.updateFieldIfNeeded(&origin.todo_changed_at, newValue: changedAt) || isUpdated
        }
        if let updatedAt = updated.updatedAt {
            isUpdated = util.updateFieldIfNeeded(&origin.todo_updated_at, newValue: updatedAt) || isUpdated
        }
        return isUpdated
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
