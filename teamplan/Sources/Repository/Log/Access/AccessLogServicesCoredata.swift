//
//  AccessLogServicesCoredata.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/10/20.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation
import CoreData

//MARK: Main

final class AccessLogServicesCoredata: AccessLogObjectManage {
    typealias Entity = AccessLogEntity
    typealias Object = AccessLog
    
    var context: NSManagedObjectContext
    init() {
        self.context = LocalStorageManager.shared.context
    }
    
    func setObject(with object: Object) -> Bool {
        createEntity(with: object)
    }
    
    // Get: Single Log
    func getLatestObject(with userId: String) throws -> Object {
        let entity = try getLatestEntity(with: userId)
        return try convertToObject(with: entity)
    }
    
    // Get: Full Log
    func getFullObjects(with userId: String) throws -> [Object] {
        let entities = try getFullEntity(with: userId)
        
        if entities.isEmpty {
            print("[AccessLogRepo] There is no log to get")
            return []
        }
        
        return try convertToObjects(with: entities)
    }
    
    func deleteObject(with userId: String) throws {
        let entities = try getFullEntity(with: userId)
        
        if entities.isEmpty {
            print("[AccessLogRepo] There is no log to delete")
            return
        }
        
        for entity in entities {
            self.context.delete(entity)
        }
    }
}

//MARK: Sub

extension AccessLogServicesCoredata {
    
    func isObjectExist(with userId: String) -> Bool {
        let request = getFullFetchRequest(with: userId, sortNeed: false)
        do {
            let count = try context.count(for: request)
            return count > 0
        } catch {
            return false
        }
    }
}

//MARK: Context Related

extension AccessLogServicesCoredata {
    
    private func createEntity(with log: Object) -> Bool {
        let entity = Entity(context: context)
        
        entity.user_id = log.userId
        entity.access_record = log.accessRecord
        
        // Optional property nil checks
        if entity.user_id == nil {
            print("[AccessLogRepo] nil detected: 'user_id'")
            return false
        }
        if entity.access_record == nil {
            print("[AccessLogRepo] nil detected: 'access_record'")
            return false
        }
        return true
    }
    
    private func getFullFetchRequest(with userId: String, sortNeed: Bool) -> NSFetchRequest<Entity> {
        let fetchRequest: NSFetchRequest<Entity> = Entity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: EntityPredicate.accessLog.format, userId)
        
        if sortNeed {
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: EntitySortBy.date.rawValue, ascending: false)]
        }
        return fetchRequest
    }
    
    private func getFullEntity(with userId: String) throws -> [Entity] {
        let request = getFullFetchRequest(with: userId, sortNeed: false)
        return try self.context.fetch(request)
    }
    
    private func getLatestEntity(with userId: String) throws -> Entity {
        let request = getFullFetchRequest(with: userId, sortNeed: true)
        request.fetchLimit = 1
        
        guard let entity = try self.context.fetch(request).first else {
            throw CoredataError.fetchFailure(serviceName: .cd, dataType: .log)
        }
        return entity
    }
}

//MARK: Util

extension AccessLogServicesCoredata {
    
    private func convertToObject(with entity: Entity) throws -> Object {
        guard let userId = entity.user_id,
              let accessRecord = entity.access_record
        else {
            throw CoredataError.convertFailure(serviceName: .cd, dataType: .log)
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
