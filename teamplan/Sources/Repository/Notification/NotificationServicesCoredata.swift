//
//  NotificationServicesCoredata.swift
//  teamplan
//
//  Created by 크로스벨 on 6/3/24.
//  Copyright © 2024 team1os. All rights reserved.
//

import CoreData
import Foundation

final class NotificationServicesCoredata {
    typealias Entity = NotificationEntity
    typealias Object = NotificationObject
    
    var objectList: [NotificationObject] = []
    
    func setObject(_ context: NSManagedObjectContext, object: NotificationObject) {
        let entity = NotificationEntity(context: context)
        createEntity(with: object, at: entity)
    }
    
    func getTotalObjectList(_ context: NSManagedObjectContext, with userId: String) -> Bool {
        do {
            let entities = try fetchAllEntities(for: userId, in: context)
            for entity in entities {
                if !convertToObject(with: entity) {
                    return false
                }
            }
            return true
        } catch {
            print("[NotifyLocalRepo] Failed to fetch all objects: \(error.localizedDescription)")
            return false
        }
    }
    
    func getCategoryObject(_ context: NSManagedObjectContext, userId: String, category: NotificationCategory) -> Bool {
        do {
            var result = false
            let entities = try fetchCategoryEntities(for: userId, in: category, context: context)
            
            for entity in entities {
                result = convertToObject(with: entity)
            }
            return result
        } catch {
            print("[NotifyLocalRepo] \(error.localizedDescription)")
            return false
        }
    }
    
    func updateObject(_ context: NSManagedObjectContext, dtoList: [NotifyUpdateDTO]) -> Bool {
        var results: [Bool] = []
        for dto in dtoList {
            var entity: NotificationEntity?

            if let challengeId = dto.challengeId {
                entity = fetchEntity(for: dto.userId, notifyId: challengeId, category: .challenge, in: context)
            }
            if let projectId = dto.projectId {
                entity = fetchEntity(for: dto.userId, notifyId: projectId, category: .project, in: context)
            }
            guard let entity = entity else {
                return false
            }
            results.append(checkUpdate(from: entity, to: dto))
        }
        if results.contains(true) {
            do {
                try context.save()
                return true
            } catch {
                print("[NotifyLocalRepo] Failed to save updated data: \(error.localizedDescription)")
                return false
            }
        }
        return false
    }
    
    func deleteObject(_ context: NSManagedObjectContext, userId: String, notifyId: Int, category: NotificationCategory) -> Bool {
        guard let entity = fetchEntity(for: userId, notifyId: notifyId, category: category, in: context) else {
            return false
        }
        context.delete(entity)
        return true
    }
    
    func deleteObjectList(_ context: NSManagedObjectContext, userId: String, notifyList: [Int : NotificationCategory]) -> Bool {
        for notify in notifyList {
            guard let entity = fetchEntity(for: userId, notifyId: notify.key, category: notify.value, in: context) else {
                return false
            }
            context.delete(entity)
        }
        return true
    }
}

// MARK: Context Related

extension NotificationServicesCoredata {
    
    // set
    private func createEntity(with object: Object, at entity: Entity) {
        
        if let challengeId = object.challengeId,
           let challengeStatus = object.challengeStatus {
            entity.notify_id = Int32(challengeId)
            entity.status = Int32(challengeStatus.rawValue)
        }
        if let projectId = object.projectId,
           let projectStatus = object.projectStatus {
            entity.notify_id = Int32(projectId)
            entity.status = Int32(projectStatus.rawValue)
        }
        entity.user_id = object.userId
        entity.title = object.title
        entity.desc = object.desc
        entity.category = Int32(object.category.rawValue)
        entity.update_at = object.updateAt
        entity.is_check = object.isCheck
    }
    
    // Fetch specific entity
    private func fetchEntity(for userId: String, notifyId: Int, category: NotificationCategory, in context: NSManagedObjectContext) -> Entity? {
        let fetchRequest: NSFetchRequest<Entity> = Entity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: EntityPredicate.singleNotify.format, userId, notifyId, category.rawValue)
        fetchRequest.fetchLimit = 1
        
        do {
            return try context.fetch(fetchRequest).first
        } catch {
            print("[NotifyLocalRepo] Failed to fetch entity: \(error.localizedDescription)")
            return nil
        }
    }
    // Fetch all entities
    private func fetchAllEntities(for userId: String, in context: NSManagedObjectContext) throws -> [Entity] {
        let fetchRequest: NSFetchRequest<Entity> = Entity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: EntityPredicate.fullNotify.format, userId)
        return try context.fetch(fetchRequest)
    }
    
    // Fetch entities by category
    private func fetchCategoryEntities(for userId: String, in category: NotificationCategory, context: NSManagedObjectContext) throws -> [Entity] {
        let fetchRequest: NSFetchRequest<Entity> = Entity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: EntityPredicate.categoryNotify.format, userId, category.rawValue)
        return try context.fetch(fetchRequest)
    }
}

//MARK: - Util

extension NotificationServicesCoredata {
    
    private func convertToObject(with entity: Entity) -> Bool {
        guard let userId = entity.user_id,
              let title = entity.title,
              let desc = entity.desc,
              let updateAt = entity.update_at,
              let category = NotificationCategory(rawValue: Int(entity.category))
        else {
            print("[NotifyLocalRepo] Failed to convert entity to object")
            return false
        }
        let notifyId = Int(entity.notify_id)
        let isCheck = entity.is_check
        
        switch category {
        case .challenge:
            let object = NotificationObject(
                userId: userId,
                challengeId: notifyId,
                challengeStatus: ChallengeNoitification(rawValue: Int(entity.status)),
                category: category,
                title: title,
                desc: desc,
                updateAt: updateAt,
                isCheck: isCheck
            )
            self.objectList.append(object)
            return true
        case .project:
            let object = NotificationObject(
                userId: userId,
                projectId: notifyId,
                projectStatus: ProjectNotification(rawValue: Int(entity.status)),
                category: category,
                title: title,
                desc: desc,
                updateAt: updateAt,
                isCheck: isCheck
            )
            self.objectList.append(object)
            return true
        default:
            print("[NotifyLocalRepo] Failed to set object")
            return false
        }
    }
    
    private func checkUpdate(from entity: NotificationEntity, to dto: NotifyUpdateDTO) -> Bool {
        let util = Utilities()
        var isUpdated = false
        
        if let _ = dto.projectId,
           let newProjectStatus = dto.newProjectStatus {
            isUpdated = util.updateIfNeeded(&entity.status, newValue: Int32(newProjectStatus.rawValue)) || isUpdated
        }
        if let _ = dto.challengeId,
           let newChallengeStatus = dto.newChallengeStatus {
            isUpdated = util.updateIfNeeded(&entity.status, newValue: Int32(newChallengeStatus.rawValue)) || isUpdated
        }
        if let newTitle = dto.newTitle {
            isUpdated = util.updateIfNeeded(&entity.title, newValue: newTitle) || isUpdated
        }
        if let newDesc = dto.newDesc {
            isUpdated = util.updateIfNeeded(&entity.desc, newValue: newDesc) || isUpdated
        }
        if let newUpdateAt = dto.newUpdateAt {
            isUpdated = util.updateIfNeeded(&entity.update_at, newValue: newUpdateAt) || isUpdated
        }
        if let isCheck = dto.isCheck {
            isUpdated = util.updateIfNeeded(&entity.is_check, newValue: isCheck) || isUpdated
        }
        return isUpdated
    }
}

//MARK: - DTO

struct NotifyUpdateDTO {
    let userId: String
    let projectId: Int?
    let newProjectStatus: ProjectNotification?
    let challengeId: Int?
    let newChallengeStatus: ChallengeNoitification?
    let newTitle: String?
    let newDesc: String?
    let newUpdateAt: Date?
    let isCheck: Bool?
    
    init(userId: String, 
         projectId: Int? = nil,
         projectStatus: ProjectNotification? = nil,
         challengeId: Int? = nil,
         challengeStatus: ChallengeNoitification? = nil,
         title: String? = nil,
         desc: String? = nil,
         updateAt: Date? = nil,
         isCheck: Bool? = nil)
    {
        self.userId = userId
        self.projectId = projectId
        self.newProjectStatus = projectStatus
        self.challengeId = challengeId
        self.newChallengeStatus = challengeStatus
        self.newTitle = title
        self.newDesc = desc
        self.newUpdateAt = updateAt
        self.isCheck = isCheck
    }
}
