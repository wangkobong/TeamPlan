//
//  ProjectExtendLogServicesCoredata.swift
//  teamplan
//
//  Created by 크로스벨 on 6/18/24.
//  Copyright © 2024 team1os. All rights reserved.
//

import Foundation
import CoreData

//MARK: Main

final class ProjectExtendLogServicesCoredata: ProjectLogObjectManage {
    typealias Entity = ProjectExtendLogEntity
    typealias Object = ProjectExtendLog
    
    var context: NSManagedObjectContext
    init() {
        self.context = LocalStorageManager.shared.context
    }
    
    func setObject(with object: ProjectExtendLog) {
        createEntity(with: object)
    }
    
    func getObjects(with projectId: Int, and userId: String) throws -> [ProjectExtendLog] {        
        let entities = try getEntityList(with: projectId, and: userId)
        return try entities.map{ try convertToObject(with: $0) }
    }
    
    func deleteObject(with projectId: Int, and userId: String) async throws {
        let entities = try getEntityList(with: projectId, and: userId)
        for entity in entities {
            context.delete(entity)
        }
    }
    
    func deleteObjects(with userId: String) throws {
        let entities = try getTotalEntity(with: userId)
        for entity in entities {
            context.delete(entity)
        }
    }
}

//MARK: Context Related

extension ProjectExtendLogServicesCoredata {
    
    private func createEntity(with object: Object) {
        let entity = Entity(context: context)
        
        entity.project_id = Int32(object.projectId)
        entity.extend_count = Int32(object.extendCount)
        entity.user_id = object.userId
        
        entity.used_drop = Int32(object.usedDrop)
        entity.stored_drop = Int32(object.storedDrop)
        
        entity.extend_period = Int32(object.extendPeriod)
        entity.extend_at = object.extendAt
        entity.new_deadline = object.newDeadline
        
        entity.registed_todo = Int32(object.totalRegistedTodo)
        entity.finished_todo = Int32(object.totalFinshedTodo)
    }
    
    private func getEntityList(with projectId: Int, and userId: String) throws -> [Entity] {
        let request: NSFetchRequest<Entity> = Entity.fetchRequest()
        request.predicate = NSPredicate(format: EntityPredicate.projectExtendLog.format, userId, projectId)
        
        return try context.fetch(request)
    }
    
    private func getTotalEntity(with userId: String) throws -> [Entity] {
        let request: NSFetchRequest<Entity> = Entity.fetchRequest()
        request.predicate = NSPredicate(format: EntityPredicate.totalProjectExtendLog.format, userId)
        
        return try context.fetch(request)
    }
}

//MARK: Util

extension ProjectExtendLogServicesCoredata {
    
    private func convertToObject(with entity: Entity) throws -> Object {
        guard let userId = entity.user_id,
              let extendAt = entity.extend_at,
              let newDeadline = entity.new_deadline
        else {
            throw CoredataError.convertFailure(serviceName: .cd, dataType: .log)
        }
        let projectId = Int(entity.project_id)
        let extendCount = Int(entity.extend_count)
        
        let usedDrop = Int(entity.used_drop)
        let storedDrop = Int(entity.used_drop)
        
        let extendPeriod = Int(entity.extend_period)
        let registedTodo = Int(entity.registed_todo)
        let finishedTodo = Int(entity.finished_todo)
        
        return Object(
            projectId: projectId,
            extendCount: extendCount,
            userId: userId,
            usedDrop: usedDrop,
            storedDrop: storedDrop,
            extendPeriod: extendPeriod,
            extendAt: extendAt,
            newDeadline: newDeadline,
            totalRegistedTodo: registedTodo,
            totalFinshedTodo: finishedTodo
        )
    }
}
