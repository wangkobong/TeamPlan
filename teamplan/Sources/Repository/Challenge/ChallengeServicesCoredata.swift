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

final class ChallengeServicesCoredata: ChallengeObjectManage {
    
    typealias Entity = ChallengeEntity
    typealias Object = ChallengeObject
    typealias DTO = ChallengeUpdateDTO
    
    var context: NSManagedObjectContext
    init() {
        self.context = LocalStorageManager.shared.context
    }
    
    // Set
    func setObject(with object: Object) -> Bool {
        return createEntity(with: object)
    }
    
    // Get
    func getObject(with challengeId: Int, and userId: String) async throws -> Object {
        try await self.context.perform {
            let entity = try self.getSingleEntity(with: challengeId, onwer: userId)
            return try self.convertToObject(with: entity)
        }
    }
    
    func getObjects(with userId: String) throws -> [Object] {
        let entities = try self.getFullEntity(owner: userId)
        return try entities.compactMap{ try self.convertToObject(with: $0) }
    }
    
    func getTartgetObjects(with userId: String, syncDate: Date) async throws -> [Object] {
        let entities = try self.getTargetEntity(with: userId, syncDate: syncDate)
        return try entities.compactMap{ try self.convertToObject(with: $0) }
    }
    
    // Update
    func updateObject(with dto: DTO) throws {
        let entity = try getSingleEntity(with: dto.challengeId, onwer: dto.userId)
        if checkUpdate(from: entity, to: dto) {
            try self.context.save()
        }
    }
    
    // Delete
    func deleteObject(with userId: String) async throws {
        
        try await self.context.perform {
            
            let entities = try self.getFullEntity(owner: userId)
            
            if entities.isEmpty {
                print("[ChallengeRepo] There is no challenge to delete")
                return
            }
            
            for entity in entities {
                self.context.delete(entity)
            }
        }
    }
}

// MARK: - Sub

extension ChallengeServicesCoredata {
    
    // : count complete challenges
    func countCompleteObjects(with userId: String) async throws -> Int {
        try await self.context.perform {
            return try self.getEntityCount(owner: userId)
        }
    }
    
    // : count every challenges
    func isObjectExist(with userId: String) -> Bool {
        let request = getFullFetchRequest(with: userId)
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
    private func createEntity(with object: Object) -> Bool {
        let entity = Entity(context: self.context)
        
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
        
        // Optional property nil checks
        if entity.user_id == nil {
            print("[ChallengeRepo] nil detected: 'user_id'")
            return false
        }
        if entity.title == nil {
            print("[ChallengeRepo] nil detected: 'title'")
            return false
        }
        if entity.desc == nil {
            print("[ChallengeRepo] nil detected: 'desc'")
            return false
        }
        if entity.selected_at == nil {
            print("[ChallengeRepo] nil detected: 'selected_at'")
            return false
        }
        if entity.unselected_at == nil {
            print("[ChallengeRepo] nil detected: 'unselected_at'")
            return false
        }
        if entity.finished_at == nil {
            print("[ChallengeRepo] nil detected: 'finished_at'")
            return false
        }
        return true
    }
    
    // signle entity
    private func getSingleFetchRequest(with challengeId: Int, onwer userId: String) -> NSFetchRequest<Entity> {
        let fetchRequest: NSFetchRequest<Entity> = Entity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: EntityPredicate.singleChallenge.format, userId, challengeId)
        fetchRequest.fetchLimit = 1
        
        return fetchRequest
    }
    
    private func getSingleEntity(with challengeId: Int, onwer userId: String) throws -> Entity {
        let request = getSingleFetchRequest(with: challengeId, onwer: userId)
        guard let entity = try context.fetch(request).first else {
            throw CoredataError.fetchFailure(serviceName: .cd, dataType: .challenge)
        }
        return entity
    }
    
    // full entity
    private func getFullFetchRequest(with userId: String) -> NSFetchRequest<Entity> {
        let fetchRequest: NSFetchRequest<Entity> = Entity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: EntityPredicate.fullChallenge.format, userId)
        
        return fetchRequest
    }
    
    private func getFullEntity(owner userId: String) throws -> [Entity] {
        let request = getFullFetchRequest(with: userId)
        return try context.fetch(request)
    }
    
    // target entity
    private func getTargetFetchRequest(with userId: String, syncDate: Date) -> NSFetchRequest<Entity> {
        let fetchRequest: NSFetchRequest<Entity> = Entity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: EntityPredicate.targetChallenge.format,
                                             userId, syncDate as NSDate, syncDate as NSDate, syncDate as NSDate)
        return fetchRequest
    }
    
    private func getTargetEntity(with userId: String, syncDate: Date) throws -> [Entity] {
        let request = getTargetFetchRequest(with: userId, syncDate: syncDate)
        return try context.fetch(request)
    }
    
    // count entity
    private func getEntityCount(owner userId: String) throws -> Int {
        let fetchRequest: NSFetchRequest<Entity> = Entity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: EntityPredicate.completeChallenge.format, userId, NSNumber(booleanLiteral: true))
        return try context.count(for: fetchRequest)
    }
}

// MARK: - Util

extension ChallengeServicesCoredata{
    
    private func convertToObject(with entity: Entity) throws -> Object {
        guard let userId = entity.user_id,
              let title = entity.title,
              let desc = entity.desc,
              let type = ChallengeType(rawValue: Int(entity.type)),
              let selectedAt = entity.selected_at,
              let unselectedAt = entity.unselected_at,
              let finishedAt = entity.finished_at 
        else {
            throw CoredataError.convertFailure(serviceName: .cd, dataType: .challenge)
        }
        return ChallengeObject(
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
