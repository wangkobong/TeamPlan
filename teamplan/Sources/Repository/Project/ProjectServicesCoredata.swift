//
//  ProjectServicesCoredata.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/08/25.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation
import CoreData

//MARK: Main

final class ProjectServicesCoredata {
    typealias Entity = ProjectEntity
    typealias Object = ProjectObject
    typealias UpdateDTO = ProjectUpdateDTO
    
    // shared
    var object = ProjectObject()
    var objectList: [ProjectObject] = []
    var dto = ProjectHomeDTO()
    var sortedDTO: [ProjectHomeDTO] = []
    var backgroundDTO: [ProjectBackgroundDTO] = []
    
    // private
    private let util = Utilities()
    
    func setObject(context: NSManagedObjectContext, object: ProjectObject) -> Bool {
        let entity = ProjectEntity(context: context)
        createEntity(with: object, at: entity)
        return checkEntity(with: entity)
    }
        
    func getSingleObject(context: NSManagedObjectContext, with userId: String, and projectId: Int) throws -> Bool {
        do {
            let entity = try getSingleEntity(context: context, with: projectId, and: userId)
            return convertToObject(with: entity)
        } catch {
            print("[Coredata-Project] Failed to get project: \(error.localizedDescription)")
            return false
        }
    }
    
    func getTotalObjects(context: NSManagedObjectContext, with userId: String) throws -> Bool {
        do {
            let entities = try getTotalEntities(context: context, with: userId)
            return convertToObjects(with: entities)
        } catch {
            print("[Coredata-Project] Failed to get projects: \(error.localizedDescription)")
            return false
        }
    }
    
    func getValidObjects(context: NSManagedObjectContext, with userId: String) throws -> Bool {
        do {
            let entities = try getValidEntities(context: context, with: userId)
            return convertToObjects(with: entities)
        } catch {
            print("[Coredata-Project] Failed to get valid projects: \(error.localizedDescription)")
            return false
        }
    }
    
    func getUploadObjects(context: NSManagedObjectContext, with userId: String) throws -> Bool {
        do {
            let entities = try getUploadEntities(context: context, with: userId)
            return convertToObjects(with: entities)
        } catch {
            print("[Coredata-Project] Failed to get upload projects: \(error.localizedDescription)")
            return false
        }
    }
        
    func updateObject(context: NSManagedObjectContext, with dto: ProjectUpdateDTO) throws -> Bool {
        let entity = try getSingleEntity(context: context, with: dto.projectId, and: dto.userId)
        return checkUpdate(from: entity, to: dto)
    }
        
    func deleteObject(context: NSManagedObjectContext, with userId: String, and projectId: Int) throws {
        let entity = try getSingleEntity(context: context, with: projectId, and: userId)
        context.delete(entity)
    }
        
    func deleteObjectList(context: NSManagedObjectContext, with userId: String) throws {
        let entities = try getTotalEntities(context: context, with: userId)
        
        if entities.isEmpty {
            print("[Coredata-Project] There is no project to delete")
            return
        }
        
        for entity in entities {
            context.delete(entity)
        }
    }
    
    func deleteTruncateObject(context: NSManagedObjectContext, with userId: String) throws -> Bool {
        let entities = try getTruncateEntities(context: context, with: userId)
        
        if entities.isEmpty {
            print("[Coredata-Project] There is no project to truncate")
            return true
        }
        
        for entity in entities {
            context.delete(entity)
        }
        return true
    }
}

// MARK: Sub

extension ProjectServicesCoredata {
    
    func getSortedDTOs(context: NSManagedObjectContext, with userId: String) -> Bool {
        do {
            let entities = try getAlertEntities(context: context, with: userId)
            self.sortedDTO = entities.compactMap { entity -> ProjectHomeDTO? in
                guard convertEntityToDTO(entity: entity) else { return nil }
                return self.dto
            }.sorted { $0.remainDay < $1.remainDay }
            return true
        } catch {
            print("[Coredata-Project] Failed to convert alert entities to DTO: \(error.localizedDescription)")
            return false
        }
    }
}

// MARK: Context Related

extension ProjectServicesCoredata {
    
    private func createEntity(with object: Object, at entity: Entity) {
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
    
    private func checkEntity(with entity: Entity) -> Bool {
        if entity.user_id == nil {
            print("[Coredata-Project] nil detected: 'user_id'")
            return false
        }
        if entity.title == nil {
            print("[Coredata-Project] nil detected: 'title'")
            return false
        }
        if entity.registed_at == nil {
            print("[Coredata-Project] nil detected: 'registed_at'")
            return false
        }
        if entity.started_at == nil {
            print("[Coredata-Project] nil detected: 'started_at'")
            return false
        }
        if entity.deadline == nil {
            print("[Coredata-Project] nil detected: 'deadline'")
            return false
        }
        if entity.finished_at == nil {
            print("[Coredata-Project] nil detected: 'finished_at'")
            return false
        }
        if entity.synced_at == nil {
            print("[Coredata-Project] nil detected: 'synced_at'")
            return false
        }
        return true
    }
    
    // sinlge entity
    private func getSingleEntity(context: NSManagedObjectContext, with projectId: Int, and userId: String) throws -> Entity {
        let fetchReq: NSFetchRequest<Entity> = Entity.fetchRequest()
        fetchReq.predicate = NSPredicate(format: EntityPredicate.project.format, userId, projectId)
        fetchReq.fetchLimit = 1
        
        guard let entity = try context.fetch(fetchReq).first else {
            throw CoredataError.fetchFailure(serviceName: .cd, dataType: .project)
        }
        return entity
    }
    
    // total entities
    private func getTotalEntities(context: NSManagedObjectContext, with userId: String) throws -> [ProjectEntity] {
        let fetchReq: NSFetchRequest<Entity> = Entity.fetchRequest()
        fetchReq.predicate = NSPredicate(format: EntityPredicate.projectTotalList.format, userId)
        return try context.fetch(fetchReq)
    }
    
    // valid entities
    private func getValidEntities(context: NSManagedObjectContext, with userId: String) throws -> [ProjectEntity] {
        let fetchReq: NSFetchRequest<Entity> = Entity.fetchRequest()
        fetchReq.predicate = NSPredicate(
            format: EntityPredicate.projectValidList.format,
            userId,
            ProjectStatus.ongoing.rawValue
        )
        return try context.fetch(fetchReq)
    }
     
    // alert entities
    private func getAlertEntities(context: NSManagedObjectContext, with userId: String) throws -> [ProjectEntity] {
        let fetchRequest: NSFetchRequest<ProjectEntity> = ProjectEntity.fetchRequest()
        let today = Date()
        
        fetchRequest.predicate = NSPredicate(
            format: EntityPredicate.projectAlertList.format,
            userId,
            today as NSDate,
            ProjectStatus.ongoing.rawValue
        )
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "deadline", ascending: true)]
        fetchRequest.fetchLimit = 3
        
        return try context.fetch(fetchRequest)
    }
    
    // upload entities
    private func getUploadEntities(context: NSManagedObjectContext, with userId: String) throws -> [ProjectEntity] {
        let fetchReq: NSFetchRequest<Entity> = Entity.fetchRequest()
        fetchReq.predicate = NSPredicate(
            format: EntityPredicate.projectUploadList.format,
            userId,
            ProjectStatus.ongoing.rawValue,
            ProjectStatus.finished.rawValue
        )
        return try context.fetch(fetchReq)
    }
        
    // truncate entities
    private func getTruncateEntities(context: NSManagedObjectContext, with userId: String) throws -> [ProjectEntity] {
        let fetchReq: NSFetchRequest<Entity> = Entity.fetchRequest()
        fetchReq.predicate = NSPredicate(
            format: EntityPredicate.projectTruncateList.format,
            userId,
            ProjectStatus.unknown.rawValue,
            ProjectStatus.exploded.rawValue,
            ProjectStatus.finished.rawValue
        )
        return try context.fetch(fetchReq)
    }
}

//MARK: - Util

extension ProjectServicesCoredata {
    
    // Project: Entity -> Object
    private func convertToObject(with entity: Entity) -> Bool {
        guard let userId = entity.user_id,
              let title = entity.title,
              let status = ProjectStatus(rawValue: Int(entity.status)),
              let registedAt = entity.registed_at,
              let startedAt = entity.started_at,
              let deadline = entity.deadline,
              let finishedAt = entity.finished_at,
              let syncedAt = entity.synced_at
        else {
            print("[Coredata-Project] Failed to convert entity to object")
            return false
        }
        
        let todoEntities = entity.todo_relationship?.allObjects as? [TodoEntity] ?? []
        let todos = convertTodoEntities(with: todoEntities, projectId: Int(entity.project_id), userId: userId)
        
        self.object = ProjectObject(
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
        return true
    }
    
    // Project: Entities -> ObjectList
    private func convertToObjects(with entities: [Entity]) -> Bool {
        self.objectList = []
        for entity in entities {
            if convertToObject(with: entity) {
                self.objectList.append(self.object)
            } else {
                print("[Coredata-Project] Failed to convert entity to object")
                return false
            }
        }
        return true
    }
    
    // Todo: Entity -> Object
    private func convertTodoEntities(with todos: [TodoEntity], projectId: Int, userId: String) -> [TodoObject] {
        return todos.compactMap { todoEntity in
            guard let desc = todoEntity.desc,
                  let status = TodoStatus(rawValue: Int(todoEntity.status)) else {
                print("[Coredata-Project] Failed to convert todo entity")
                return nil
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
    }
    
    // Project: Entity -> DTO
    private func convertEntityToDTO(entity: ProjectEntity) -> Bool {
        guard let title = entity.title,
              let startAt = entity.started_at,
              let deadline = entity.deadline else {
            print("[Coredata-Project] Failed to convert entity to ProjectHomeDTO")
            return false
        }
        do {
            let today = Date()
            let remainDay = try Utilities().calculateDatePeriod(with: today, and: deadline)
            let totalTerm = try Utilities().calculateDatePeriod(with: startAt, and: deadline)
            let progressedTerm = try Utilities().calculateDatePeriod(with: startAt, and: today)
            
            self.dto = ProjectHomeDTO(
                projectId: Int(entity.project_id),
                title: title,
                startedAt: startAt,
                deadline: deadline,
                finished: entity.status != ProjectStatus.ongoing.rawValue,
                remainDay: remainDay,
                remainTodo: Int(entity.total_registed_todo) - Int(entity.finished_todo),
                totalTerm: totalTerm,
                progressedTerm: progressedTerm
            )
            return true
        } catch {
            print("[Coredata-Project] Failed to calculate project periods: \(error.localizedDescription)")
            return false
        }
    }

    // Project: Update
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

// MARK: - DTO

// Update
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

// Home
struct ProjectHomeDTO: Identifiable {
    let id = UUID().uuidString
    let projectId: Int
    let title: String
    let finished: Bool
    let startedAt: Date
    let deadline: Date
    let remainDay: Int
    let remainTodo: Int
    let totalTerm: Int
    let progressedTerm: Int
    
    init(tempDate: Date = Date()){
        self.projectId = 0
        self.title = "unknown"
        self.startedAt = tempDate
        self.deadline = tempDate
        self.finished = false
        self.remainDay = 0
        self.remainTodo = 0
        self.totalTerm = 0
        self.progressedTerm = 0
    }
    
    init(projectId: Int,
         title: String,
         startedAt: Date,
         deadline: Date,
         finished: Bool,
         remainDay: Int,
         remainTodo: Int,
         totalTerm: Int,
         progressedTerm: Int
    ) {
        self.projectId = projectId
        self.title = title
        self.startedAt = startedAt
        self.deadline = deadline
        self.finished = finished
        self.remainDay = remainDay
        self.remainTodo = remainTodo
        self.totalTerm = totalTerm
        self.progressedTerm = progressedTerm
    }
}

//MARK: BackGround

struct ProjectBackgroundDTO {
    
    let projectId: Int
    let startedAt: Date
    let deadline: Date
    
    init(temp: Date = Date()){
        self.projectId = 0
        self.startedAt = temp
        self.deadline = temp
    }
    
    init(projectId: Int,
         startedAt: Date,
         deadline: Date) {
        self.projectId = projectId
        self.startedAt = startedAt
        self.deadline = deadline
    }
}

extension ProjectServicesCoredata {
    
    func getBackgroundDTOList(context: NSManagedObjectContext, userId: String) throws -> Bool {
        do {
            let entities = try getValidEntities(context: context, with: userId)
            if entities.isEmpty {
                print("[Coredata-Project] There is no project to convert to BackgroundDTO")
                return true
            }
            self.backgroundDTO = try entities.map{ try convertEntityToDTO(with: $0) }
            return true
        } catch {
            print("[Coredata-Project] Failed to get entity to ProjectHomeDTO: \(error.localizedDescription)")
            return false
        }
    }
    
    private func convertEntityToDTO(with entity: Entity) throws -> ProjectBackgroundDTO {
        guard let startedAt = entity.started_at,
              let deadline = entity.deadline else {
            throw CoredataError.fetchFailure(serviceName: .cd, dataType: .project)
        }
        return ProjectBackgroundDTO(
            projectId: Int(entity.project_id),
            startedAt: startedAt,
            deadline: deadline
        )
    }
}

