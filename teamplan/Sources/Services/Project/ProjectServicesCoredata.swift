//
//  ProjectServicesCoredata.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/08/25.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation
import CoreData

final class ProjectServicesCoredata: ProjectObjectManage {
    typealias Entity = ProjectEntity
    typealias Object = ProjectObject
    typealias DTO = ProjectUpdateDTO
    typealias CardDTO = ProjectCardDTO
    
    var context: NSManagedObjectContext
    init(coredataController: CoredataProtocol) {
        self.context = coredataController.context
    }
    
    func setObject(with object: ProjectObject) throws {
        createEntity(with: object)
        try context.save()
    }
    
    func getDTO(with userId: String) throws -> [CardDTO] {
        let entities = try getEntities(with: userId)
        return try entities.map { try convertToDTO(with: $0) }
    }
    
    func getObject(with userId: String, and projectId: Int) throws -> ProjectObject {
        let entity = try getEntity(with: projectId, and: userId)
        return try convertToObject(with: entity)
    }
    
    func getObjects(with userId: String) throws -> [ProjectObject] {
        let entities = try getEntities(with: userId)
        return try entities.map{ try convertToObject(with: $0) }
    }
    
    func updateObject(with dto: ProjectUpdateDTO) throws {
        let entity = try getEntity(with: dto.projectId, and: dto.userId)
        if checkUpdate(from: entity, to: dto) {
            try self.context.save()
        }
    }
    
    func deleteObject(with userId: String, and projectId: Int) throws {
        let entity = try getEntity(with: projectId, and: userId)
        self.context.delete(entity)
        try self.context.save()
    }
    
}


// MARK: Support Function
extension ProjectServicesCoredata{
    
    private func getEntity(with projectId: Int, and userId: String) throws -> Entity {
        
        let fetchReq: NSFetchRequest<Entity> = Entity.fetchRequest()
        fetchReq.predicate = NSPredicate(format: EntityPredicate.project.format, projectId, userId)
        fetchReq.fetchLimit = 1
        
        guard let entity = try fetchEntity(with: fetchReq, and: self.context) else {
            throw CoredataError.fetchFailure(serviceName: .project)
        }
        return entity
    }
    
    private func getEntities(with userId: String) throws -> [ProjectEntity] {

        let fetchReq: NSFetchRequest<Entity> = Entity.fetchRequest()
        fetchReq.predicate = NSPredicate(format: EntityPredicate.projectList.format, userId)
        return try self.context.fetch(fetchReq)
    }
    
    
}

//MARK: - Set
extension ProjectServicesCoredata {
    
    private func createEntity(with object: Object) {
        let entity = Entity(context: context)
        
        entity.project_id = Int32(object.projectId)
        entity.user_id = object.userId
        entity.title = object.title
        entity.status = Int32(object.status.rawValue)
        entity.total_registed_todo = Int32(object.totalRegistedTodo)
        entity.daily_registed_todo = Int32(object.dailyRegistedTodo)
        entity.finished_todo = Int32(object.finishedTodo)
        entity.alerted = Int32(object.alerted)
        entity.extended_count = Int32(object.extendedCount)
        entity.registed_at = object.registedAt
        entity.started_at = object.startedAt
        entity.deadline = object.deadline
        entity.finished_at = object.finishedAt
        entity.synced_at = object.syncedAt
    }
}


//MARK: - Convert to Object
extension ProjectServicesCoredata {
    
    private func convertToObject(with entity: Entity) throws -> Object {
        guard let userId = entity.user_id,
              let title = entity.title,
              let status = ProjectStatus(rawValue: Int(entity.status)),
              let registedAt = entity.registed_at,
              let startedAt = entity.started_at,
              let deadline = entity.deadline,
              let finishedAt = entity.finished_at,
              let syncedAt = entity.synced_at
        else {
            throw CoredataError.convertFailure(serviceName: .project)
        }
        let todoEntities = entity.todo_relationship?.allObjects as? [TodoEntity] ?? []
        let todos = try convertTodoEntity(with: todoEntities, projectId: Int(entity.project_id), userId: userId)
        
        return ProjectObject(
            projectId: Int(entity.project_id),
            userId: userId,
            title: title,
            status: status,
            todos: todos,
            totalRegistedTodo: Int(entity.total_registed_todo),
            dailyRegistedTodo: Int(entity.daily_registed_todo),
            finishedTodo: Int(entity.finished_todo),
            alerted: Int(entity.alerted),
            extendedCount: Int(entity.extended_count),
            registedAt: registedAt,
            startedAt: startedAt,
            deadline: deadline,
            finishedAt: finishedAt,
            syncedAt: syncedAt
        )
    }
    
    private func convertTodoEntity(with todos: [TodoEntity], projectId: Int, userId: String) throws -> [TodoObject] {
        let todoObjects: [TodoObject] = todos.isEmpty ? [] : try todos.map { todoEntity in
            guard let desc = todoEntity.desc,
                  let status = TodoStatus(rawValue: Int(todoEntity.status)) else {
                throw CoredataError.convertFailure(serviceName: .project)
            }
            return TodoObject(
                projectId: projectId,
                todoId: Int(todoEntity.todo_id),
                userId: userId,
                desc: desc,
                pinned: todoEntity.pinned,
                status: status
            )
        }
        return todoObjects
    }
}


// MARK: - Convert to DTO
struct ProjectCardDTO{
    
    let projectId: Int
    let title: String
    let finished: Bool
    let startedAt: Date
    let deadline: Date
    let registedTodo: Int
    let finishedTodo: Int
    
    init(projectId: Int, 
         title: String,
         startedAt: Date,
         deadline: Date,
         finished: Bool,
         registedTodo: Int,
         finishedTodo: Int
    ) {
        self.projectId = projectId
        self.title = title
        self.startedAt = startedAt
        self.deadline = deadline
        self.finished = finished
        self.registedTodo = registedTodo
        self.finishedTodo = finishedTodo
    }
}

extension ProjectServicesCoredata {
    
    private func convertToDTO(with entity: Entity) throws -> ProjectCardDTO {
        var status: Bool?
        guard let title = entity.title,
              let type = ProjectStatus(rawValue: Int(entity.status)),
              let startedAt = entity.started_at,
              let deadline = entity.deadline
        else {
            throw CoredataError.convertFailure(serviceName: .project)
        }
        
        if type == .ongoing {
            status = false
        } else {
            status = true
        }
        
        return ProjectCardDTO(
            projectId: Int(entity.project_id),
            title: title,
            startedAt: startedAt,
            deadline: deadline,
            finished: status!,
            registedTodo: Int(entity.total_registed_todo),
            finishedTodo: Int(entity.finished_todo)
        )
    }
}

// MARK: - Update
struct ProjectUpdateDTO{
    
    let userId: String
    let projectId: Int
    var newTitle: String?
    var newStatus: ProjectStatus?
    var newTotalRegistedTodo: Int?
    var newDailyRegistedTodo: Int?
    var newFinishedTodo: Int?
    var newAlerted: Int?
    var newExtendedCount: Int?
    var newStartedAt: Date?
    var newDeadline: Date?
    var newFinishedAt: Date?
    var newSyncedAt: Date?
    
    init(
        projectId: Int,
        userId: String,
        newTitle: String? = nil,
        newStatus: ProjectStatus? = nil,
        newTotalRegistedTodo: Int? = nil,
        newDailyRegistedTodo: Int? = nil,
        newFinishedTodo: Int? = nil,
        newAlerted: Int? = nil,
        newExtendedCount: Int? = nil,
        newStartedAt: Date? = nil,
        newDeadline: Date? = nil,
        newFinishedAt: Date? = nil,
        newSyncedAt: Date? = nil
    ) {
        self.projectId = projectId
        self.userId = userId
        self.newTitle = newTitle
        self.newStatus = newStatus
        self.newTotalRegistedTodo = newTotalRegistedTodo
        self.newDailyRegistedTodo = newDailyRegistedTodo
        self.newFinishedTodo = newFinishedTodo
        self.newAlerted = newAlerted
        self.newExtendedCount = newExtendedCount
        self.newStartedAt = newStartedAt
        self.newDeadline = newDeadline
        self.newFinishedAt = newFinishedAt
        self.newSyncedAt = newSyncedAt
    }
}

extension ProjectServicesCoredata {
    private func checkUpdate(from entity: ProjectEntity, to dto: ProjectUpdateDTO) -> Bool {
        let util = Utilities()
        var isUpdated = false
        
        if let newTitle = dto.newTitle {
            isUpdated = util.updateIfNeeded(&entity.title, newValue: newTitle) || isUpdated
        }
        if let newStatus = dto.newStatus {
            isUpdated = util.updateIfNeeded(&entity.status, newValue: Int32(newStatus.rawValue)) || isUpdated
        }
        if let newTotalRegistedTodo = dto.newTotalRegistedTodo {
            isUpdated = util.updateIfNeeded(&entity.total_registed_todo, newValue: Int32(newTotalRegistedTodo)) || isUpdated
        }
        if let newDailyRegistedTodo = dto.newDailyRegistedTodo {
            isUpdated = util.updateIfNeeded(&entity.daily_registed_todo, newValue: Int32(newDailyRegistedTodo)) || isUpdated
        }
        if let newFinishedTodo = dto.newFinishedTodo {
            isUpdated = util.updateIfNeeded(&entity.finished_todo, newValue: Int32(newFinishedTodo)) || isUpdated
        }
        if let newAlerted = dto.newAlerted {
            isUpdated = util.updateIfNeeded(&entity.alerted, newValue: Int32(newAlerted)) || isUpdated
        }
        if let newExtendedCount = dto.newExtendedCount {
            isUpdated = util.updateIfNeeded(&entity.extended_count, newValue: Int32(newExtendedCount)) || isUpdated
        }
        if let newStartedAt = dto.newStartedAt {
            isUpdated = util.updateIfNeeded(&entity.started_at, newValue: newStartedAt) || isUpdated
        }
        if let newDeadline = dto.newDeadline {
            isUpdated = util.updateIfNeeded(&entity.deadline, newValue: newDeadline) || isUpdated
        }
        if let newFinishedAt = dto.newFinishedAt {
            isUpdated = util.updateIfNeeded(&entity.finished_at, newValue: newFinishedAt) || isUpdated
        }
        if let newSyncedAt = dto.newSyncedAt {
            isUpdated = util.updateIfNeeded(&entity.synced_at, newValue: newSyncedAt) || isUpdated
        }
        return isUpdated
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
