//
//  ChallengeServicesCoredata.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/08/26.
//  Copyright © 2023 team1os. All rights reserved.
//

import CoreData
import Foundation

//MARK: Main

final class ChallengeServicesCoredata {
    
    typealias Entity = ChallengeEntity
    typealias Object = ChallengeObject
    typealias DTO = ChallengeUpdateDTO
    
    var object = ChallengeObject()
    var objects = [ChallengeObject]()
    
    // Set
    func setObject(context: NSManagedObjectContext, object: ChallengeObject) -> Bool {
        let entity = ChallengeEntity(context: context)
        createEntity(with: object, at: entity)
        return checkEntity(with: entity)
    }
    
    // Get
    func getSingleObject(context: NSManagedObjectContext, challengeId: Int, userId: String) throws -> Bool {
        let entity = try getSingleEntity(context: context, challengeId: challengeId, owner: userId)
        return convertToObject(with: entity)
    }
    
    func getTotalObject(context: NSManagedObjectContext, userId: String) throws -> Bool {
        let entities = try getTotalEntity(context: context, owner: userId)
        return convertToObjects(with: entities)
    }
    
    func getChangedObjects(context: NSManagedObjectContext, userId: String, syncDate: Date) throws -> Bool {
        let entities = try getChangedEntity(context: context, userId: userId, syncDate: syncDate)
        return convertToObjects(with: entities)
    }
    
    func getMyObjects(context: NSManagedObjectContext, userId: String) throws -> Bool {
        let entities = try getMyEntities(context: context, with: userId)
        return convertToObjects(with: entities)
    }
    
    // Update
    func updateObject(context: NSManagedObjectContext, dto: ChallengeUpdateDTO) throws -> Bool {
        let entity = try getSingleEntity(context: context, challengeId: dto.challengeId, owner: dto.userId)
        return checkUpdate(from: entity, to: dto)
    }
    
    // Delete
    func deleteObject(context: NSManagedObjectContext, userId: String) throws {
        let entities = try getTotalEntity(context: context, owner: userId)
        
        if entities.isEmpty {
            print("[Coredata-Challenge] There is no challenge to delete")
            return
        }
        
        for entity in entities {
            context.delete(entity)
        }
    }
}

// MARK: - Sub

extension ChallengeServicesCoredata {
    
    // : count complete challenges
    func countCompleteObjects(context: NSManagedObjectContext, userId: String) throws -> Int {
        return try countCompleteEntity(context: context, owner: userId)
    }
    
    // : count every challenges
    func isObjectExist(context: NSManagedObjectContext, userId: String) -> Bool {
        let request = constructTotalFetchRequest(with: userId)
        do {
            let count = try context.count(for: request)
            return count > 0
        } catch {
            return false
        }
    }
}

// MARK: - Context Related

extension ChallengeServicesCoredata {
    
    // set entity
    private func createEntity(with object: ChallengeObject, at entity: ChallengeEntity) {
        entity.challenge_id = Int32(object.challengeId)
        entity.user_id = object.userId
        entity.type = Int32(object.type.rawValue)
        entity.title = object.title
        entity.desc = object.desc
        entity.goal = Int32(object.goal)
        entity.reward = Int32(object.reward)
        entity.step = Int32(object.step)
        entity.select_status = object.selectStatus
        entity.status = object.status
        entity.lock = object.lock
        entity.progress = Int32(object.progress)
        entity.selected_at = object.selectedAt
        entity.unselected_at = object.unselectedAt
        entity.finished_at = object.finishedAt
    }
    
    private func checkEntity(with entity: ChallengeEntity) -> Bool {
        if entity.user_id == nil {
            print("[Coredata-Challenge] nil detected: 'user_id'")
            return false
        }
        if entity.title == nil {
            print("[Coredata-Challenge] nil detected: 'title'")
            return false
        }
        if entity.desc == nil {
            print("[Coredata-Challenge] nil detected: 'desc'")
            return false
        }
        if entity.selected_at == nil {
            print("[Coredata-Challenge] nil detected: 'selected_at'")
            return false
        }
        if entity.unselected_at == nil {
            print("[Coredata-Challenge] nil detected: 'unselected_at'")
            return false
        }
        if entity.finished_at == nil {
            print("[Coredata-Challenge] nil detected: 'finished_at'")
            return false
        }
        return true
    }
    
    // signle entity
    private func constructSingleFetchRequest(with challengeId: Int, owner userId: String) -> NSFetchRequest<Entity> {
        let fetchRequest: NSFetchRequest<Entity> = Entity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: EntityPredicate.singleChallenge.format, userId, challengeId)
        fetchRequest.fetchLimit = 1
        
        return fetchRequest
    }
    
    private func getSingleEntity(context: NSManagedObjectContext, challengeId: Int, owner userId: String) throws -> Entity {
        let request = constructSingleFetchRequest(with: challengeId, owner: userId)
        guard let entity = try context.fetch(request).first else {
            throw CoredataError.fetchFailure(serviceName: .cd, dataType: .challenge)
        }
        return entity
    }
    
    // full entity
    private func constructTotalFetchRequest(with userId: String) -> NSFetchRequest<Entity> {
        let fetchRequest: NSFetchRequest<Entity> = Entity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: EntityPredicate.fullChallenge.format, userId)
        
        return fetchRequest
    }
    
    private func getTotalEntity(context: NSManagedObjectContext, owner userId: String) throws -> [Entity] {
        let request = constructTotalFetchRequest(with: userId)
        return try context.fetch(request)
    }
    
    // my entity
    private func constructMyFetchReqeust(with userId: String) -> NSFetchRequest<Entity> {
        let fetchRequest: NSFetchRequest<Entity> = Entity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: EntityPredicate.myChallenge.format, userId, true)
        
        return fetchRequest
    }
    
    private func getMyEntities(context: NSManagedObjectContext, with userId: String) throws -> [Entity] {
        let request = constructMyFetchReqeust(with: userId)
        return try context.fetch(request)
    }
    
    // target entity
    private func constructChangedFetchRequest(with userId: String, syncDate: Date) -> NSFetchRequest<Entity> {
        let fetchRequest: NSFetchRequest<Entity> = Entity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: EntityPredicate.changedChallenge.format,
                                             userId, syncDate as NSDate, syncDate as NSDate, syncDate as NSDate)
        return fetchRequest
    }
    
    private func getChangedEntity(context: NSManagedObjectContext, userId: String, syncDate: Date) throws -> [Entity] {
        let request = constructChangedFetchRequest(with: userId, syncDate: syncDate)
        return try context.fetch(request)
    }
    
    // count entity
    private func countCompleteEntity(context: NSManagedObjectContext, owner userId: String) throws -> Int {
        let fetchRequest: NSFetchRequest<Entity> = Entity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: EntityPredicate.completeChallenge.format, userId, NSNumber(booleanLiteral: true))
        return try context.count(for: fetchRequest)
    }
}

// MARK: - Util

extension ChallengeServicesCoredata{
    
    private func convertToObject(with entity: ChallengeEntity) -> Bool {
        guard let userId = entity.user_id,
              let title = entity.title,
              let desc = entity.desc,
              let type = ChallengeType(rawValue: Int(entity.type)),
              let selectedAt = entity.selected_at,
              let unselectedAt = entity.unselected_at,
              let finishedAt = entity.finished_at
        else {
            print("[Coredata-Challenge] Failed to fetch data from entity")
            return false
        }
        self.object = ChallengeObject(
            challengeId: Int(entity.challenge_id),
            userId: userId,
            title: title,
            desc: desc,
            goal: Int(entity.goal),
            type: type,
            reward: Int(entity.reward),
            step: Int(entity.step),
            version: Int(entity.version),
            status: entity.status,
            lock: entity.lock,
            progress: Int(entity.progress),
            selectStatus: entity.select_status,
            selectedAt: selectedAt,
            unselectedAt: unselectedAt,
            finishedAt: finishedAt
        )
        return true
    }
    
    private func convertToObjects(with entities: [ChallengeEntity]) -> Bool {
        self.objects = []
        if entities.isEmpty {
            print("[Coredata-Challenge] There is no entity no convert")
            return true
        }
        for entity in entities {
            guard let userId = entity.user_id,
                  let title = entity.title,
                  let desc = entity.desc,
                  let type = ChallengeType(rawValue: Int(entity.type)),
                  let selectedAt = entity.selected_at,
                  let unselectedAt = entity.unselected_at,
                  let finishedAt = entity.finished_at
            else {
                print("[Coredata-Challenge] Failed to fetch data from entity")
                return false
            }
            let challengeObject = ChallengeObject(
                challengeId: Int(entity.challenge_id),
                userId: userId,
                title: title,
                desc: desc,
                goal: Int(entity.goal),
                type: type,
                reward: Int(entity.reward),
                step: Int(entity.step),
                version: Int(entity.version),
                status: entity.status,
                lock: entity.lock,
                progress: Int(entity.progress),
                selectStatus: entity.select_status,
                selectedAt: selectedAt,
                unselectedAt: unselectedAt,
                finishedAt: finishedAt
            )
            self.objects.append(challengeObject)
        }
        return true
    }
    
    private func checkUpdate(from entity: Entity, to dto: DTO) -> Bool {
        let util = Utilities()
        var isUpdated = false
        
        if let newSelectStatus = dto.newSelectStatus {
            isUpdated = util.updateIfNeeded(&entity.select_status, newValue: newSelectStatus) || isUpdated
        }
        if let newStatus = dto.newStatus {
            isUpdated = util.updateIfNeeded(&entity.status, newValue: newStatus) || isUpdated
        }
        if let newLock = dto.newLock {
            isUpdated = util.updateIfNeeded(&entity.lock, newValue: newLock) || isUpdated
        }
        if let newProgress = dto.newProgress {
            isUpdated = util.updateIfNeeded(&entity.progress, newValue: Int32(newProgress)) || isUpdated
        }
        if let newSelectedAt = dto.newSelectedAt {
            isUpdated = util.updateIfNeeded(&entity.selected_at, newValue: newSelectedAt) || isUpdated
        }
        if let newUnSelectedAt = dto.newUnSelectedAt {
            isUpdated = util.updateIfNeeded(&entity.unselected_at, newValue: newUnSelectedAt) || isUpdated
        }
        if let newFinishedAt = dto.newFinishedAt {
            isUpdated = util.updateIfNeeded(&entity.finished_at, newValue: newFinishedAt) || isUpdated
        }
        return isUpdated
    }
}

// MARK: - DTO

struct ChallengeUpdateDTO {
    
    let challengeId: Int
    let userId: String
    var newStatus: Bool?
    var newLock: Bool?
    var newProgress: Int?
    var newSelectStatus: Bool?
    var newSelectedAt: Date?
    var newUnSelectedAt: Date?
    var newFinishedAt: Date?
    
    init(challengeId: Int, 
         userId: String,
         newStatus: Bool? = nil,
         newLock: Bool? = nil,
         newProgress: Int? = nil,
         newSelectStatus: Bool? = nil,
         newSelectedAt: Date? = nil,
         newUnSelectedAt: Date? = nil,
         newFinishedAt: Date? = nil)
    {
        self.challengeId = challengeId
        self.userId = userId
        self.newStatus = newStatus
        self.newLock = newLock
        self.newProgress = newProgress
        self.newSelectStatus = newSelectStatus
        self.newSelectedAt = newSelectedAt
        self.newUnSelectedAt = newUnSelectedAt
        self.newFinishedAt = newFinishedAt
    }
}
