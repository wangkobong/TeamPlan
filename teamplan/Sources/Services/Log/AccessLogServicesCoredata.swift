//
//  AccessLogServicesCoredata.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/10/20.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation
import CoreData

final class AccessLogServicesCoredata: LogObjectManage {
    typealias Entity = AccessLogEntity
    typealias Object = AccessLog
    
    var context: NSManagedObjectContext
    init(coredataController: CoredataProtocol = CoredataMainController.shared) {
        self.context = coredataController.context
    }
    
    func setObject(with object: Object) throws {
        createEntity(with: object)
        try self.context.save()
    }
    
    // Single Log
    func getLatestObject(with userId: String) throws -> Object {
        let entity = try getLatestEntity(with: userId)
        return try convertToObject(with: entity)
    }
    
    // Full Log
    func getFullObjects(with userId: String) throws -> [Object] {
        let entities = try getFullEntity(with: userId)
        return try convertToObjects(with: entities)
    }
    
    // SyncedAt ~ Recent Log
    func getPartialObjects(with userId: String, and syncedAt: Date) throws -> [Object] {
        let entities = try getPartialEntity(with: userId, at: syncedAt)
        return try convertToObjects(with: entities)
    }
    
    func deleteObject(with userId: String) throws {
        let entities = try getFullEntity(with: userId)
        for entity in entities {
            self.context.delete(entity)
        }
        try self.context.save()
    }
    
    func isObjectExist(with userId: String) -> Bool {
        let request = getFullFetchRequest(with: userId)
        do {
            let count = try context.count(for: request)
            return count > 0
        } catch {
            return false
        }
    }
}

extension AccessLogServicesCoredata{
    
    private func createEntity(with log: Object) {
        let entity = Entity(context: context)
        
        entity.user_id = log.userId
        entity.access_record = log.accessRecord
    }
    
    
    // Single & Full entity
    private func getFullFetchRequest(with userId: String) -> NSFetchRequest<Entity> {
        let fetchRequest: NSFetchRequest<Entity> = Entity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: EntityPredicate.accessLog.format, userId)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: EntitySortBy.date.rawValue, ascending: false)]
        
        return fetchRequest
    }
    
    private func getLatestEntity(with userId: String) throws -> Entity {
        let request = getFullFetchRequest(with: userId)
        request.fetchLimit = 1
        
        guard let entity = try self.context.fetch(request).first else {
            throw CoredataError.fetchFailure(serviceName: .log)
        }
        return entity
    }
    
    private func getFullEntity(with userId: String) throws -> [Entity] {
        let request = getFullFetchRequest(with: userId)
        return try self.context.fetch(request)
    }
    
    
    // Partial entity
    private func getPartialFetchRequest(with userId: String, at syncedAt: Date) -> NSFetchRequest<Entity> {
        let fetchRequest: NSFetchRequest<Entity> = Entity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: EntityPredicate.targetLog.format, userId, syncedAt as NSDate)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: EntitySortBy.date.rawValue, ascending: false)]
        
        return fetchRequest
    }

    private func getPartialEntity(with userId: String, at syncedAt: Date) throws -> [Entity] {
        let request = getPartialFetchRequest(with: userId, at: syncedAt)
        return try self.context.fetch(request)
    }
    
    
    // Converter
    private func convertToObject(with entity: Entity) throws -> Object {
        guard let userId = entity.user_id,
              let accessRecord = entity.access_record
        else {
            throw CoredataError.convertFailure(serviceName: .log)
        }
        return AccessLog(userId: userId, accessDate: accessRecord)
    }
    
    private func convertToObjects(with entities: [Entity]) throws -> [Object] {
        var logList: [Object] = []
        for entity in entities {
            let object = try convertToObject(with: entity)
            logList.append(AccessLog(userId: object.userId, accessDate: object.accessRecord))
        }
        return logList
    }
}

