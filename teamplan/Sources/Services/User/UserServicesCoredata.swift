//
//  UserServiceCoredata.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/08/22.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation
import CoreData

final class UserServicesCoredata: FullObjectManage {
    typealias Entity = UserEntity
    typealias Object = UserObject
    typealias DTO = UserUpdateDTO
    
    var context: NSManagedObjectContext
    init(coredataController: CoredataProtocol) {
        self.context = coredataController.context
    }
    
    func setObject(with object: UserObject) throws {
        createEntity(with: object, and: object.createdAt)
        try self.context.save()
    }
    
    func getObject(with userId: String) throws -> UserObject {
        let entity = try getEntity(with: userId)
        return try convertToObject(with: entity)
    }
    
    func updateObject(with dto: DTO) throws {
        let entity = try getEntity(with: dto.userId)
        if checkUpdate(from: entity, to: dto) {
            try context.save()
        }
    }
    
    func deleteObject(with userId: String) throws {
        let entity = try getEntity(with: userId)
        context.delete(entity)
        try context.save()
    }
}


// MARK: - Set Extension
extension UserServicesCoredata{
    
    private func createEntity(with object: UserObject, and setDate: Date) {
        let entity = UserEntity(context: context)
        
        entity.user_id = object.userId
        entity.email = object.email
        entity.name = object.name
        entity.social_type = object.socialType.rawValue
        entity.status = object.status.rawValue
        entity.access_log_head = Int32(object.accessLogHead)
        entity.created_at = object.createdAt
        entity.changed_at = object.changedAt
        entity.synced_at = object.syncedAt
    }
}


// MARK: - Get Extension
extension UserServicesCoredata{
    
    private func getEntity(with userId: String) throws -> UserEntity {
        let fetchRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: EntityPredicate.user.format, userId)
        
        guard let entity = try fetchEntity(with: fetchRequest, and: self.context) else {
            throw CoredataError.fetchFailure(serviceName: .user)
        }
        return entity
    }
    
    private func convertToObject(with entity: UserEntity) throws -> UserObject {
        guard let userId = entity.user_id,
              let email = entity.email,
              let name = entity.name,
              let stringSocialType = entity.social_type,
              let socialType = Providers(rawValue: stringSocialType),
              let stringStatus = entity.status,
              let status = UserStatus(rawValue: stringStatus),
              let createdAt = entity.created_at,
              let changedAt = entity.changed_at,
              let syncedAt = entity.synced_at
        else {
            throw CoredataError.convertFailure(serviceName: .user)
        }
        return UserObject(
            userId: userId,
            email: email,
            name: name,
            socialType: socialType,
            status: status,
            accessLogHead: Int(entity.access_log_head),
            createdAt: createdAt,
            changedAt: changedAt,
            syncedAt: syncedAt)
    }
}


// MARK: - Update Extension
struct UserUpdateDTO{
    let userId: String
    let newEmail: String?
    let newName: String?
    let newStatus: UserStatus?
    let newLogHead: Int?
    let newChangedAt: Date?
    let newSyncedAt: Date?
    
    init(userId: String,
         newEmail: String? = nil,
         newName: String? = nil,
         newStatus: UserStatus? = nil,
         newLogHead: Int? = nil,
         newChangedAt: Date? = nil,
         newSyncedAt: Date? = nil)
    {
        self.userId = userId
        self.newEmail = newEmail
        self.newName = newName
        self.newStatus = newStatus
        self.newLogHead = newLogHead
        self.newChangedAt = newChangedAt
        self.newSyncedAt = newSyncedAt
    }
}

extension UserServicesCoredata{
    
    private func checkUpdate(from entity: UserEntity, to dto: UserUpdateDTO) -> Bool {
        let util = Utilities()
        var isUpdated = false
        
        if let newEmail = dto.newEmail {
            isUpdated = util.updateIfNeeded(&entity.email, newValue: newEmail) || isUpdated
        }
        if let newName = dto.newName {
            isUpdated = util.updateIfNeeded(&entity.name, newValue: newName) || isUpdated
        }
        if let newStatus = dto.newStatus?.rawValue {
            isUpdated = util.updateIfNeeded(&entity.status, newValue: newStatus) || isUpdated
        }
        if let newLogHead = dto.newLogHead {
            isUpdated = util.updateIfNeeded(&entity.access_log_head, newValue: Int32(newLogHead)) || isUpdated
        }
        if let newChangedAt = dto.newChangedAt {
            isUpdated = util.updateIfNeeded(&entity.changed_at, newValue: newChangedAt) || isUpdated
        }
        if let newSyncedAt = dto.newSyncedAt {
            isUpdated = util.updateIfNeeded(&entity.synced_at, newValue: newSyncedAt) || isUpdated
        }
        return isUpdated
    }
}
