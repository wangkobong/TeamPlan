//
//  UserServiceCoredata.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/08/22.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation
import CoreData

//MARK: Main

final class UserServicesCoredata {
    typealias Entity = UserEntity
    typealias Object = UserObject
    typealias DTO = UserUpdateDTO
    
    var object = UserObject()
    
    func setObject(context: NSManagedObjectContext, object: UserObject) -> Bool {
        let entity = UserEntity(context: context)
        createEntity(with: object, at: entity)
        return true
    }
    
    func getObject(context: NSManagedObjectContext, userId: String) throws -> Bool {
        let entity = try getEntity(context: context, userId: userId)
        return convertToObject(with: entity)
    }
    
    func updateObject(context: NSManagedObjectContext, dto: UserUpdateDTO) throws -> Bool {
        let entity = try getEntity(context: context, userId: dto.userId)
        return checkUpdate(from: entity, to: dto)
    }
    
    func deleteObject(context: NSManagedObjectContext, userId: String) throws {
        let entity = try getEntity(context: context, userId: userId)
        context.delete(entity)
    }
}

// MARK: - Sub

extension UserServicesCoredata {
    
    func isObjectExist(context: NSManagedObjectContext, userId: String) -> Bool {
        let reqeust = constructFetchRequest(with: userId)
        do {
            let count = try context.count(for: reqeust)
            return count > 0
        } catch {
            return false
        }
    }
}

// MARK: - Context Related

extension UserServicesCoredata {
    
    private func createEntity(with object: Object, at entity: Entity) {
        entity.user_id = object.userId
        entity.name = object.name
        entity.user_status = object.userStatus.rawValue
        entity.access_log_head = Int32(object.accessLogHead)
        entity.created_at = object.createdAt
        
        entity.online_status = object.onlineStatus
        entity.changed_at = object.changedAt
        
        entity.server_id = "unknown"
        entity.email = "unknown"
        entity.social_type = Providers.unknown.rawValue
        entity.synced_at = Date()
    }
    
    private func constructFetchRequest(with userId: String) -> NSFetchRequest<Entity> {
        let fetchRequest: NSFetchRequest<Entity> = UserEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: EntityPredicate.user.format, userId)
        
        return fetchRequest
    }
    
    private func getEntity(context: NSManagedObjectContext, userId: String) throws -> Entity {
        let request = constructFetchRequest(with: userId)
        guard let entity = try context.fetch(request).first else {
            throw CoredataError.fetchFailure(serviceName: .cd, dataType: .user)
        }
        return entity
    }
}

// MARK: - Util

extension UserServicesCoredata{
    
    private func convertToObject(with entity: UserEntity) -> Bool {
        guard let userId = entity.user_id,
              let name = entity.name,
              let stringUserStatus = entity.user_status,
              let userStatus = UserStatus(rawValue: stringUserStatus),
              let createdAt = entity.created_at,
              let changedAt = entity.changed_at,
              let serverId = entity.server_id,
              let email = entity.email,
              let stringSocialType = entity.social_type,
              let socialType = Providers(rawValue: stringSocialType),
              let syncedAt = entity.synced_at
        else {
            print("[Coredata-User] Failed to convert entity to object")
            return false
        }
        self.object = UserObject(
            userId: userId,
            name: name,
            userStatus: userStatus,
            accessLogHead: Int(entity.access_log_head),
            createdAt: createdAt,
            onlineStatus: entity.online_status,
            changedAt: changedAt,
            serverId: serverId,
            email: email,
            socialType: socialType,
            syncedAt: syncedAt
        )
        return true
    }
    
    private func checkUpdate(from entity: UserEntity, to dto: UserUpdateDTO) -> Bool {
        let util = Utilities()
        var isUpdated = false
        
        if let newName = dto.newName {
            isUpdated = util.updateIfNeeded(&entity.name, newValue: newName) || isUpdated
        }
        if let newUserStatus = dto.newUserStatus?.rawValue {
            isUpdated = util.updateIfNeeded(&entity.user_status, newValue: newUserStatus) || isUpdated
        }
        if let newLogHead = dto.newLogHead {
            isUpdated = util.updateIfNeeded(&entity.access_log_head, newValue: Int32(newLogHead)) || isUpdated
        }
        if let newOnlineStatus = dto.newOnlineStatus {
            isUpdated = util.updateIfNeeded(&entity.online_status, newValue: newOnlineStatus) || isUpdated
        }
        if let newChangedAt = dto.newChangedAt {
            isUpdated = util.updateIfNeeded(&entity.changed_at, newValue: newChangedAt) || isUpdated
        }
        if let newEmail = dto.newEmail {
            isUpdated = util.updateIfNeeded(&entity.email, newValue: newEmail) || isUpdated
        }
        if let newSyncedAt = dto.newSyncedAt {
            isUpdated = util.updateIfNeeded(&entity.synced_at, newValue: newSyncedAt) || isUpdated
        }
        return isUpdated
    }
}

// MARK: - DTO

struct UserUpdateDTO{
    let userId: String
    let newName: String?
    let newUserStatus: UserStatus?
    let newLogHead: Int?
    let newOnlineStatus: Bool?
    let newChangedAt: Date?
    let newEmail: String?
    let newSyncedAt: Date?
    
    init(userId: String,
         newName: String? = nil,
         newUserStatus: UserStatus? = nil,
         newLogHead: Int? = nil,
         newOnlineStatus: Bool? = nil,
         newChangedAt: Date? = nil,
         newEmail: String? = nil,
         newSyncedAt: Date? = nil
    ){
        self.userId = userId
        self.newName = newName
        self.newUserStatus = newUserStatus
        self.newLogHead = newLogHead
        self.newOnlineStatus = newOnlineStatus
        self.newChangedAt = newChangedAt
        self.newEmail = newEmail
        self.newSyncedAt = newSyncedAt
    }
}
