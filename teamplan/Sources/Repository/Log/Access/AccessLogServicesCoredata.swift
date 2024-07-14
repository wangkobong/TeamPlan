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

final class AccessLogServicesCoredata {
    typealias Entity = AccessLogEntity
    typealias Object = AccessLog
    
    var object = AccessLog()
    var objects = [AccessLog]()
    
    func setObject(context: NSManagedObjectContext, object: Object) -> Bool {
        let entity = AccessLogEntity(context: context)
        createEntity(with: object, at: entity)
        return checkEntity(with: entity)
    }
    
    // Get: Single Log
    func getLatestObject(context: NSManagedObjectContext, userId: String) throws -> Bool {
        let entity = try getLatestEntity(context: context, userId: userId)
        return convertToObject(with: entity)
    }
    
    // Get: Full Log
    func getFullObjects(context: NSManagedObjectContext, userId: String) throws -> Bool {
        let entities = try getFullEntity(context: context, userId: userId)
        
        if entities.isEmpty {
            print("[Coredata-AccessLog] There is no log to get")
            return false
        }
        
        return convertToObjects(with: entities)
    }
    
    func deleteObject(context: NSManagedObjectContext, userId: String) throws {
        let entities = try getFullEntity(context: context, userId: userId)
        
        if entities.isEmpty {
            print("[Coredata-AccessLog] There is no log to delete")
            return
        }
        
        for entity in entities {
            context.delete(entity)
        }
    }
}

//MARK: Sub

extension AccessLogServicesCoredata {
    
    func isObjectExist(context: NSManagedObjectContext, userId: String) -> Bool {
        let request = constructFullFetchRequest(with: userId, sortNeed: false)
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
    
    private func createEntity(with log: Object, at entity: AccessLogEntity) {
        entity.user_id = log.userId
        entity.access_record = log.accessRecord
    }
    
    private func checkEntity(with entity: AccessLogEntity) -> Bool {
        if entity.user_id == nil {
            print("[Coredata-AccessLog] nil detected: 'user_id'")
            return false
        }
        if entity.access_record == nil {
            print("[Coredata-AccessLog] nil detected: 'access_record'")
            return false
        }
        return true
    }
    
    private func constructFullFetchRequest(with userId: String, sortNeed: Bool) -> NSFetchRequest<AccessLogEntity> {
        let fetchRequest: NSFetchRequest<AccessLogEntity> = AccessLogEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: EntityPredicate.accessLog.format, userId)
        
        if sortNeed {
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: EntitySortBy.date.rawValue, ascending: false)]
        }
        return fetchRequest
    }
    
    private func getFullEntity(context: NSManagedObjectContext, userId: String) throws -> [AccessLogEntity] {
        let request = constructFullFetchRequest(with: userId, sortNeed: false)
        return try context.fetch(request)
    }
    
    private func getLatestEntity(context: NSManagedObjectContext, userId: String) throws -> AccessLogEntity {
        let request = constructFullFetchRequest(with: userId, sortNeed: true)
        request.fetchLimit = 1
        
        guard let entity = try context.fetch(request).first else {
            throw CoredataError.fetchFailure(serviceName: .cd, dataType: .aclog)
        }
        return entity
    }
}

//MARK: Util

extension AccessLogServicesCoredata {
    
    private func convertToObject(with entity: AccessLogEntity) -> Bool {
        guard let userId = entity.user_id,
              let accessRecord = entity.access_record
        else {
            print("[Coredata-AccessLog] Failed to fetch data from entity")
            return false
        }
        self.object = AccessLog(userId: userId, accessDate: accessRecord)
        return true
    }
    
    private func convertToObjects(with entities: [AccessLogEntity]) -> Bool {
        self.objects = entities.compactMap { entity in
            guard let userId = entity.user_id,
                  let accessRecord = entity.access_record
            else {
                print("[Coredata-AccessLog] Failed to convert entity to object")
                return nil
            }
            return AccessLog(userId: userId, accessDate: accessRecord)
        }
        return !self.objects.isEmpty
    }
}
