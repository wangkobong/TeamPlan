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
    func getObject(with userId: String) throws -> Object {
        let entities = try getEntities(with: userId)
        guard let entity = entities.first else {
            throw CoredataError.fetchFailure(serviceName: .log)
        }
        return try convertToObject(with: entity)
    }
    
    // Every Log
    func getObjects(with userId: String) throws -> [Object] {
        let entities = try getEntities(with: userId)
        return try convertToObjects(with: entities)
    }
    
    // SyncedAt ~ Recent Log
    func getTargetObjects(with userId: String, and syncedAt: Date) throws -> [Object] {
        let entities = try getTargetEntities(with: userId, and: syncedAt)
        return try convertToObjects(with: entities)
    }
    
    func deleteObject(with userId: String) throws {
        let entities = try getEntities(with: userId)
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
    
    private func getEntities(with userId: String) throws -> [Entity] {
        
        let fetchReq: NSFetchRequest<Entity> = Entity.fetchRequest()
        fetchReq.predicate = NSPredicate(format: EntityPredicate.accessLog.format, userId)
        fetchReq.sortDescriptors = [NSSortDescriptor(key: EntitySortBy.date.rawValue, ascending: false)]
        return try self.context.fetch(fetchReq)
    }
    
    private func getTargetEntities(with userId: String, and syncedAt: Date) throws -> [Entity] {
        
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

