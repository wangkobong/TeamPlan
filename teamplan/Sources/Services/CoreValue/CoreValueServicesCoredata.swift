//
//  CoreValueServicesCoredata.swift
//  teamplan
//
//  Created by 크로스벨 on 3/15/24.
//  Copyright © 2024 team1os. All rights reserved.
//

import Foundation
import CoreData

final class CoreValueServicesCoredata: CoreValueObjectManage {
    typealias Entity = CoreValueEntity
    typealias Object = CoreValueObject
    
    var context: NSManagedObjectContext
    init(coredataController: CoredataProtocol) {
        self.context = coredataController.context
    }
    
    func setObject(with object: CoreValueObject) throws {
        createEntity(with: object)
        try self.context.save()
    }
    
    func getObject(with userId: String) throws -> CoreValueObject {
        let entity = try getEntity(with: userId)
        return try convertToObject(with: entity)
    }
    
    func deleteObject(with userId: String) throws {
        let entity = try getEntity(with: userId)
        self.context.delete(entity)
        try self.context.save()
    }
}

extension CoreValueServicesCoredata {

    private func createEntity(with object: Object) {
        let entity = Entity(context: self.context)
        
        entity.user_id = object.userId
        entity.project_regist_limit = Int32(object.projectRegistLimit)
        entity.todo_regist_limit = Int32(object.todoRegistLimit)
        entity.drop_convert_ratio = object.dropConvertRatio
        entity.sync_cycle = Int32(object.syncCycle)
    }
    
    private func convertToObject(with entity: CoreValueEntity) throws -> CoreValueObject {
        guard let userId = entity.user_id else {
            throw CoredataError.convertFailure(serviceName: .coreValue)
        }
        return CoreValueObject(
            userId: userId,
            projectRegistLimit: Int(entity.project_regist_limit),
            todoRegistLimit: Int(entity.todo_regist_limit),
            dropConvertRatio:  entity.drop_convert_ratio,
            syncCycle:  Int(entity.sync_cycle))
    }
    
    private func getEntity(with userId: String) throws -> CoreValueEntity {
        let fetchRequest: NSFetchRequest<Entity> = Entity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: EntityPredicate.coreValue.format, userId)
        
        guard let entity = try fetchEntity(with: fetchRequest, and: self.context) else {
            throw CoredataError.fetchFailure(serviceName: .coreValue)
        }
        return entity
    }
}

