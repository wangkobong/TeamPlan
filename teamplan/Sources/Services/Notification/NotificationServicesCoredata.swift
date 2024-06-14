//
//  NotificationServicesCoredata.swift
//  teamplan
//
//  Created by 크로스벨 on 6/3/24.
//  Copyright © 2024 team1os. All rights reserved.
//

import CoreData
import Foundation

final class NotificationServicesCoredata: NotificationObjectManage {
    typealias Entity = NotificationEntity
    typealias Object = NotificationObject
    
    private var context: NSManagedObjectContext
    init(coredataController: CoredataProtocol = CoredataMainController.shared) {
        self.context = coredataController.context
    }
    
    func setObject(with object: NotificationObject) async throws {
        try createEntity(with: object)
        try self.context.save()
    }
    
    func getFullObject(with userId: String) async throws -> [NotificationObject] {
        let entities = try getEntities(with: userId)
        return try entities.map { entity in
            try convertToObject(with: entity)
        }
    }
    
    func getCategoryObject(with userId: String, and category: NotificationCategory) async throws -> [NotificationObject] {
        let categoryEntities = try getCategoryEntities(with: userId, and: category)
        return try categoryEntities.map { entity in
            try convertToObject(with: entity)
        }
    }
    
    func deleteObject(with userId: String, and notifyId: Int) async throws {
        let entity = try getEntity(with: userId, and: notifyId)
        self.context.delete(entity)
        try self.context.save()
    }
    
    func deleteObjects(with userId: String, and notifyIds: [Int]) async throws {
        for notifyId in notifyIds {
            let entity = try getEntity(with: userId, and: notifyId)
            self.context.delete(entity)
        }
        try self.context.save()
    }
}

//MARK: Coredata
//TODO: Need to Fix Custome Error

extension NotificationServicesCoredata {
    
    // set
    private func createEntity(with object: Object) throws {
        let entity = Entity(context: self.context)
        
        if let challengeId = object.challengeId {
            entity.notify_id = Int32(challengeId)
        } else if let projectId = object.projectId {
            entity.notify_id = Int32(projectId)
        } else {
            print("[NotifyRepo] Failed to extract both 'projectId' and 'challengeId'")
            throw CoredataError.fetchFailure(serviceName: .challenge, dataType: .log)
        }
        
        entity.user_id = object.userId
        entity.title = object.title
        entity.desc = object.desc
        entity.category = Int32(object.category.rawValue)
        entity.date = object.date
        entity.is_check = object.isCheck
    }
    
    // get
    private func getEntity(with userId: String, and notifyId: Int) throws -> Entity {
        let fetchReq: NSFetchRequest<Entity> = Entity.fetchRequest()
        fetchReq.predicate = NSPredicate(format: EntityPredicate.singleNotify.format, userId, notifyId)
        fetchReq.fetchLimit = 1
        
        guard let entity = try fetchEntity(with: fetchReq, and: self.context) else {
            throw CoredataError.fetchFailure(serviceName: .cd, dataType: .log)
        }
        return entity
    }
    
    private func getEntities(with userId: String) throws -> [Entity] {
        let fetchReq: NSFetchRequest<Entity> = Entity.fetchRequest()
        fetchReq.predicate = NSPredicate(format: EntityPredicate.fullNotify.format, userId)
        
        return try context.fetch(fetchReq)
    }
    
    private func getCategoryEntities(with userId: String, and category: NotificationCategory) throws -> [Entity] {
        let fetchReq: NSFetchRequest<Entity> = Entity.fetchRequest()
        fetchReq.predicate = NSPredicate(format: EntityPredicate.categoryNotify.format, userId, category.rawValue)
        
        return try context.fetch(fetchReq)
    }
}


//MARK: Converter
//TODO: Need to Fix Custome Error

extension NotificationServicesCoredata {
    
    private func convertToObject(with entity: Entity) throws -> Object {
        guard let userId = entity.user_id,
              let title = entity.title,
              let desc = entity.desc,
              let date = entity.date,
              let type = NotificationCategory(rawValue: Int(entity.category))
        else {
            throw CoredataError.convertFailure(serviceName: .cd, dataType: .log)
        }
        let notifyId = Int(entity.notify_id)
        let isCheck = entity.is_check
        
        switch type {
        case .challenge:
            return NotificationObject(
                userId: userId,
                challengeId: notifyId,
                type: type,
                title: title,
                desc: desc,
                date: date,
                isCheck: isCheck
            )
        case .project:
            return NotificationObject(
                userId: userId,
                projectId: notifyId,
                type: type,
                title: title,
                desc: desc,
                date: date,
                isCheck: isCheck
            )
        default:
            throw CoredataError.convertFailure(serviceName: .cd, dataType: .log)
        }
    }
}
