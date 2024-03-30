//
//  ChallengeServicesCoredata.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/08/26.
//  Copyright © 2023 team1os. All rights reserved.
//

import CoreData
import Foundation

final class ChallengeServicesCoredata: ChallengeObjectManage {
    typealias Entity = ChallengeEntity
    typealias Object = ChallengeObject
    typealias DTO = ChallengeUpdateDTO
    
    var context: NSManagedObjectContext
    init(coredataController: CoredataProtocol) {
        self.context = coredataController.context
    }
    
    func setObject(with object: Object) throws {
        createEntity(with: object)
        try self.context.save()
    }
    
    func getObject(with challengeId: Int, and userId: String) throws -> Object {
        let entity = try getEntity(with: challengeId, onwer: userId)
        return try convertToObject(with: entity)
    }
    
    func getObjects(with userId: String) throws -> [Object] {
        let entities = try getEntities(owner: userId)
        return try entities.compactMap{ try convertToObject(with: $0) }
    }
    
    func updateObject(with dto: DTO) throws {
        let entity = try getEntity(with: dto.challengeId, onwer: dto.userId)
        if checkUpdate(from: entity, to: dto) {
            try self.context.save()
        }
    }
    
    func deleteObject(with userId: String) throws {
        let entities = try getEntities(owner: userId)
        for entity in entities {
            self.context.delete(entity)
        }
        try self.context.save()
    }
}


// MARK: - Set Extension
extension ChallengeServicesCoredata{
    
    private func createEntity(with object: Object) {
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
    }
}


// MARK: - Get Extension
extension ChallengeServicesCoredata{

    private func getEntity(with challengeId: Int, onwer userId: String) throws -> Entity {
        let fetchReq: NSFetchRequest<Entity> = Entity.fetchRequest()
        fetchReq.predicate = NSPredicate(format: EntityPredicate.singleChallenge.format, challengeId, userId)
        fetchReq.fetchLimit = 1
        
        guard let entity = try self.context.fetch(fetchReq).first else {
            throw CoredataError.fetchFailure(serviceName: .challenge)
        }
        return entity
    }
    
    private func getEntities(owner userId: String) throws -> [Entity] {
        let fetchReq: NSFetchRequest<Entity> = Entity.fetchRequest()
        print(EntityPredicate.multiChallenge.format, userId)
        fetchReq.predicate = NSPredicate(format: EntityPredicate.multiChallenge.format, userId)
        return try self.context.fetch(fetchReq)
    }
    
    private func convertToObject(with entity: Entity) throws -> Object {
        guard let userId = entity.user_id,
              let title = entity.title,
              let desc = entity.desc,
              let type = ChallengeType(rawValue: Int(entity.type)),
              let selectedAt = entity.selected_at,
              let unselectedAt = entity.unselected_at,
              let finishedAt = entity.finished_at 
        else {
            throw CoredataError.convertFailure(serviceName: .challenge)
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
}


// MARK: - Update Extension
struct ChallengeUpdateDTO {
    
    let challengeId: Int
    let userId: String
    let newStatus: Bool?
    let newLock: Bool?
    let newProgress: Int?
    let newSelectStatus: Bool?
    let newSelectedAt: Date?
    let newUnSelectedAt: Date?
    let newFinishedAt: Date?
    
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
extension ChallengeServicesCoredata{
    
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

