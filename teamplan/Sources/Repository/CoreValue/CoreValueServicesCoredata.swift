//
//  CoreValueServicesCoredata.swift
//  teamplan
//
//  Created by 크로스벨 on 3/15/24.
//  Copyright © 2024 team1os. All rights reserved.
//

import Foundation
import CoreData

final class CoreValueServicesCoredata {
    typealias Entity = CoreValueEntity
    typealias Object = CoreValueObject
    
    var object = CoreValueObject()
    
    func setObject(context: NSManagedObjectContext, object: CoreValueObject) -> Bool {
        let entity = CoreValueEntity(context: context)
        createEntity(with: object, at: entity)
        return checkEntity(with: entity)
    }
    
    func getObject(context: NSManagedObjectContext, userId: String) throws -> Bool {
        let entity = try getEntity(context: context, userId: userId)
        return convertToObject(with: entity)
    }
    
    func deleteObject(context: NSManagedObjectContext, userId: String) throws {
        let entity = try getEntity(context: context, userId: userId)
        context.delete(entity)
    }
    
    func isObjectExist(context: NSManagedObjectContext, userId: String) -> Bool {
        let request = getFetchRequest(with: userId)
        do {
            let count = try context.count(for: request)
            return count > 0
        } catch {
            return false
        }
    }
}

extension CoreValueServicesCoredata {

    private func createEntity(with object: CoreValueObject, at entity: CoreValueEntity) {
        entity.user_id = object.userId
        entity.project_regist_limit = Int32(object.projectRegistLimit)
        entity.todo_regist_limit = Int32(object.todoRegistLimit)
        entity.drop_convert_ratio = object.dropConvertRatio
        entity.sync_cycle = Int32(object.syncCycle)
    }
    
    private func checkEntity(with entity: CoreValueEntity) -> Bool {
        if entity.user_id == nil {
            print("[Coredata-CoreValue] nil detected: 'user_id'")
            return false
        }
        return true
    }
    
    private func convertToObject(with entity: CoreValueEntity) -> Bool {
        guard let userId = entity.user_id else {
            print("[Coredata-CoreValue] Failed to fetch data from entity")
            return false
        }
        self.object = CoreValueObject(
            userId: userId,
            projectRegistLimit: Int(entity.project_regist_limit),
            todoRegistLimit: Int(entity.todo_regist_limit),
            dropConvertRatio: entity.drop_convert_ratio,
            syncCycle: Int(entity.sync_cycle)
        )
        return true
    }
    
    private func getFetchRequest(with userId: String) -> NSFetchRequest<CoreValueEntity> {
        let fetchRequest: NSFetchRequest<CoreValueEntity> = CoreValueEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: EntityPredicate.coreValue.format, userId)
        
        return fetchRequest
    }
    
    private func getEntity(context: NSManagedObjectContext, userId: String) throws -> CoreValueEntity {
        let request = getFetchRequest(with: userId)
        guard let entity = try context.fetch(request).first else {
            throw CoredataError.fetchFailure(serviceName: .cd, dataType: .coreValue)
        }
        return entity
    }
}

