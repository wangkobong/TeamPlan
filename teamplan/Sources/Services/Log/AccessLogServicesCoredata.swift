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
    init(coredataController: CoredataProtocol) {
        self.context = coredataController.context
    }
    
    func setObject(with object: Object) throws {
        createEntity(with: object)
        try self.context.save()
    }
    
    // Single Log
    func getSingleObject(with userId: String) throws -> Object {
        let entity = try getSingleEntity(with: userId)
        return try convertToObject(with: entity)
    }
    
    // Full Log
    func getFullObjects(with userId: String) throws -> [Object] {
        let entities = try getFullEntities(with: userId)
        return try convertToObjects(with: entities)
    }
    
    // SyncedAt ~ Recent Log
    func getPartialObjects(with userId: String, and syncedAt: Date) throws -> [Object] {
        let entities = try getPartialEntities(with: userId, and: syncedAt)
        return try convertToObjects(with: entities)
    }
    
    func deleteObject(with userId: String) throws {
        let entities = try getFullEntities(with: userId)
        for entity in entities {
            self.context.delete(entity)
        }
        try self.context.save()
    }
}

extension AccessLogServicesCoredata{
    
    private func createEntity(with log: Object) {
        let entity = Entity(context: context)
        
        entity.user_id = log.userId
        entity.access_record = log.accessRecord
    }
    
    private func getSingleEntity(with userId: String) throws -> Entity {
        
        let fetchReq: NSFetchRequest<Entity> = Entity.fetchRequest()
        fetchReq.predicate = NSPredicate(format: EntityPredicate.accessLog.format, userId)
        fetchReq.sortDescriptors = [NSSortDescriptor(key: EntitySortBy.date.rawValue, ascending: false)]
        fetchReq.fetchLimit = 1
        
        guard let entity = try self.context.fetch(fetchReq).first else {
            throw CoredataError.fetchFailure(serviceName: .log)
        }
        return entity
    }
    
    private func getFullEntities(with userId: String) throws -> [Entity] {
        
        let fetchReq: NSFetchRequest<Entity> = Entity.fetchRequest()
        fetchReq.predicate = NSPredicate(format: EntityPredicate.accessLog.format, userId)
        fetchReq.sortDescriptors = [NSSortDescriptor(key: EntitySortBy.date.rawValue, ascending: false)]
        return try self.context.fetch(fetchReq)
    }
    
    private func getPartialEntities(with userId: String, and syncedAt: Date) throws -> [Entity] {
        
        let fetchReq: NSFetchRequest<Entity> = Entity.fetchRequest()
        fetchReq.predicate = NSPredicate(format: EntityPredicate.targetLog.format, userId, syncedAt as NSDate)
        fetchReq.sortDescriptors = [NSSortDescriptor(key: EntitySortBy.date.rawValue, ascending: false)]
        return try self.context.fetch(fetchReq)
    }
    
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

