//
//  CoreValueServicesCoredata.swift
//  teamplan
//
//  Created by 크로스벨 on 3/15/24.
//  Copyright © 2024 team1os. All rights reserved.
//

import Foundation
import CoreData

final class CoreValueServicesCoredata: ReadOnlyObjectManage {
    typealias Entity = CoreValueEntity
    typealias Object = CoreValueObject
    
    var context: NSManagedObjectContext
    
    init(coredataController: CoredataProtocol) {
        self.context = coredataController.context
    }
    
    func getObject(with userId: String) throws -> CoreValueObject {
        let entity = try getEntity(with: userId)
        return try convertToObject(with: entity)
    }
}

extension CoreValueServicesCoredata {

    private func getEntity(with userId: String) throws -> CoreValueEntity {
        let fetchRequest: NSFetchRequest<Entity> = Entity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: EntityPredicate.coreValue.format, userId)
        
        guard let entity = try fetchEntity(with: fetchRequest, and: self.context) else {
            throw CoredataError.fetchFailure(serviceName: .coreValue)
        }
        return entity
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
}

