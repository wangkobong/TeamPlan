//
//  StatisticsServiceCoredata.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/10/10.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation
import CoreData

//MARK: Main

final class StatisticsServicesCoredata {
    typealias Entity = StatisticsEntity
    typealias Object = StatisticsObject
    typealias DTO = StatUpdateDTO
    
    var object = StatisticsObject()
    private let util = Utilities()
    
    func setObject(context: NSManagedObjectContext, object: StatisticsObject) throws -> Bool {
        let entity = StatisticsEntity(context: context)
        try createEntity(with: object, at: entity)
        return true
    }
    
    func getObject(context: NSManagedObjectContext, userId: String) throws -> Bool {
        let entity = try getEntity(context: context, userId: userId)
        return convertToObject(with: entity)
    }
    
    func updateObject(context: NSManagedObjectContext, dto: StatUpdateDTO) throws -> Bool {
        let entity = try getEntity(context: context, userId: dto.userId)
        return try checkUpdate(from: entity, to: dto)
    }
    
    func deleteObject(context: NSManagedObjectContext, userId: String) throws {
        let entity = try getEntity(context: context, userId: userId)
        context.delete(entity)
    }
}

//MARK: Sub

extension StatisticsServicesCoredata {
    
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

extension StatisticsServicesCoredata {
    
    private func constructFetchRequest(with userId: String) -> NSFetchRequest<Entity> {
        let fetchRequest: NSFetchRequest<Entity> = Entity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: EntityPredicate.stat.format, userId)
        
        return fetchRequest
    }
    
    private func getEntity(context: NSManagedObjectContext, userId: String) throws -> Entity {
        let request = constructFetchRequest(with: userId)
        guard let entity = try context.fetch(request).first else {
            throw CoredataError.fetchFailure(serviceName: .cd, dataType: .stat)
        }
        return entity
    }
    
    private func createEntity(with object: StatisticsObject, at entity: StatisticsEntity) throws {
        let stringChallengeStep = try util.convertToJSON(data: object.challengeStepStatus)
        let stringMyChallenges = try util.convertToJSON(data: object.mychallenges)
        
        entity.user_id = object.userId
        entity.term = Int32(object.term)
        entity.drop = Int32(object.drop)
        entity.total_registed_projects = Int32(object.totalRegistedProjects)
        entity.total_finished_projects = Int32(object.totalFinishedProjects)
        entity.total_failed_projects = Int32(object.totalFailedProjects)
        entity.total_alerted_projects = Int32(object.totalAlertedProjects)
        entity.total_extended_projects = Int32(object.totalExtendedProjects)
        entity.total_registed_todos = Int32(object.totalRegistedTodos)
        entity.total_finished_todos = Int32(object.totalFinishedTodos)
        entity.challenge_step_status = stringChallengeStep
        entity.mychallenges = stringMyChallenges
        entity.synced_at = object.syncedAt
    }
    
    private func checkEntity(with entity: StatisticsEntity) -> Bool {
        if entity.user_id == nil {
            print("[Coredata-Stat] nil detected: 'user_id'")
            return false
        }
        if entity.challenge_step_status == nil {
            print("[Coredata-Stat] nil detected: 'challenge_step_status'")
            return false
        }
        if entity.mychallenges == nil {
            print("[Coredata-Stat] nil detected: 'mychallenges'")
            return false
        }
        if entity.synced_at == nil {
            print("[Coredata-Stat] nil detected: 'synced_at'")
            return false
        }
        return true
    }
}

// MARK: - Util

extension StatisticsServicesCoredata {
    
    private func convertToObject(with entity: StatisticsEntity) -> Bool {
        guard let userId = entity.user_id,
              let challengeStepStatusString = entity.challenge_step_status,
              let myChallengesString = entity.mychallenges
        else {
            print("[Coredata-Stat] Failed to fetch entity data")
            return false
        }
        do {
            let challengeStepStatus = try util.convertFromJSON(jsonString: challengeStepStatusString, type: [Int: Int].self)
            let myChallenges = try util.convertFromJSON(jsonString: myChallengesString, type: [Int].self)
            
            self.object = StatisticsObject(
                userId: userId,
                term: Int(entity.term),
                drop: Int(entity.drop),
                totalRegistedProjects: Int(entity.total_registed_projects),
                totalFinishedProjects: Int(entity.total_finished_projects),
                totalFailedProjects: Int(entity.total_failed_projects),
                totalAlertedProjects: Int(entity.total_alerted_projects),
                totalExtendedProjects: Int(entity.total_extended_projects),
                totalRegistedTodos: Int(entity.total_registed_todos),
                totalFinishedTodos: Int(entity.total_finished_todos),
                challengeStepStatus: challengeStepStatus,
                mychallenges: myChallenges,
                syncedAt: entity.synced_at ?? Date()
            )
            return true
            
        } catch {
            print("[Coredata-Stat] Failed to convert entity to object: \(error.localizedDescription)")
            return false
        }
    }
    
    private func checkUpdate(from entity: StatisticsEntity, to dto: StatUpdateDTO) throws -> Bool {
        let util = Utilities()
        var isUpdated = false
        
        if let newTerm = dto.newTerm {
            isUpdated = util.updateIfNeeded(&entity.term, newValue: Int32(newTerm)) || isUpdated
        }
        if let newDrop = dto.newDrop {
            isUpdated = util.updateIfNeeded(&entity.drop, newValue: Int32(newDrop)) || isUpdated
        }
        if let newTotalRegistedProjects = dto.newTotalRegistedProjects {
            isUpdated = util.updateIfNeeded(&entity.total_registed_projects, newValue: Int32(newTotalRegistedProjects)) || isUpdated
        }
        if let newTotalFinishedProjects = dto.newTotalFinishedProjects {
            isUpdated = util.updateIfNeeded(&entity.total_finished_projects, newValue: Int32(newTotalFinishedProjects)) || isUpdated
        }
        if let newTotalFailedProjects = dto.newTotalFailedProjects {
            isUpdated = util.updateIfNeeded(&entity.total_failed_projects, newValue: Int32(newTotalFailedProjects)) || isUpdated
        }
        if let newTotalAlertedProjects = dto.newTotalAlertedProjects {
            isUpdated = util.updateIfNeeded(&entity.total_alerted_projects, newValue: Int32(newTotalAlertedProjects)) || isUpdated
        }
        if let newTotalExtendedProjects = dto.newTotalExtendedProjects {
            isUpdated = util.updateIfNeeded(&entity.total_extended_projects, newValue: Int32(newTotalExtendedProjects)) || isUpdated
        }
        if let newTotalRegistedTodos = dto.newTotalRegistedTodos {
            isUpdated = util.updateIfNeeded(&entity.total_registed_todos, newValue: Int32(newTotalRegistedTodos)) || isUpdated
        }
        if let newTotalFinishedTodos = dto.newTotalFinishedTodos {
            isUpdated = util.updateIfNeeded(&entity.total_finished_todos, newValue: Int32(newTotalFinishedTodos)) || isUpdated
        }
        if let newChallengeStepStatus = dto.newChallengeStepStatus {
            isUpdated = util.updateIfNeeded(&entity.challenge_step_status, newValue: try Utilities().convertToJSON(data: newChallengeStepStatus)) || isUpdated
        }
        if let newMyChallenges = dto.newMyChallenges {
            isUpdated = util.updateIfNeeded(&entity.mychallenges, newValue: try Utilities().convertToJSON(data: newMyChallenges)) || isUpdated
        }
        if let newSyncedAt = dto.newSyncedAt {
            isUpdated = util.updateIfNeeded(&entity.synced_at, newValue: newSyncedAt) || isUpdated
        }
        return isUpdated
    }
}
    
// MARK: - DTO

struct StatUpdateDTO {
    let userId: String
    var newTerm: Int?
    var newDrop: Int?
    var newTotalRegistedProjects: Int?
    var newTotalFinishedProjects: Int?
    var newTotalFailedProjects: Int?
    var newTotalAlertedProjects: Int?
    var newTotalExtendedProjects: Int?
    var newTotalRegistedTodos: Int?
    var newTotalFinishedTodos: Int?
    var newChallengeStepStatus: [Int: Int]?
    var newMyChallenges: [Int]?
    var newSyncedAt: Date?
    
    init(userId: String,
         newTerm: Int? = nil,
         newDrop: Int? = nil,
         newTotalRegistedProjects: Int? = nil,
         newTotalFinishedProjects: Int? = nil,
         newTotalFailedProjects: Int? = nil,
         newTotalAlertedProjects: Int? = nil,
         newTotalExtendedProjects: Int? = nil,
         newTotalRegistedTodos: Int? = nil,
         newTotalFinishedTodos: Int? = nil,
         newChallengeStepStatus: [Int: Int]? = nil,
         newMyChallenges: [Int]? = nil,
         newSyncedAt: Date? = nil) {
        self.userId = userId
        self.newTerm = newTerm
        self.newDrop = newDrop
        self.newTotalRegistedProjects = newTotalRegistedProjects
        self.newTotalFinishedProjects = newTotalFinishedProjects
        self.newTotalFailedProjects = newTotalFailedProjects
        self.newTotalAlertedProjects = newTotalAlertedProjects
        self.newTotalExtendedProjects = newTotalExtendedProjects
        self.newTotalRegistedTodos = newTotalRegistedTodos
        self.newTotalFinishedTodos = newTotalFinishedTodos
        self.newChallengeStepStatus = newChallengeStepStatus
        self.newMyChallenges = newMyChallenges
        self.newSyncedAt = newSyncedAt
    }
}

struct StatDTO {
    
    let userId: String
    var term: Int
    var drop: Int
    var totalRegistedProjects: Int
    var totalFinishedProjects: Int
    var totalFailedProjects: Int
    var totalAlertedProjects: Int
    var totalExtendedProjects: Int
    var totalRegistedTodos: Int
    var totalFinishedTodos: Int
    var challengeStepStatus: [Int : Int]
    var myChallenges: [Int]
    
    init(){
        self.userId = ""
        self.term = 0
        self.drop = 0
        self.totalRegistedProjects = 0
        self.totalFinishedProjects = 0
        self.totalFailedProjects = 0
        self.totalAlertedProjects = 0
        self.totalExtendedProjects = 0
        self.totalRegistedTodos = 0
        self.totalFinishedTodos = 0
        self.challengeStepStatus = [ : ]
        self.myChallenges = []
    }
    
    init(with object: StatisticsObject){
        self.userId = object.userId
        self.term = object.term
        self.drop = object.drop
        self.totalRegistedProjects = object.totalRegistedProjects
        self.totalFinishedProjects = object.totalFinishedProjects
        self.totalFailedProjects = object.totalFailedProjects
        self.totalAlertedProjects = object.totalAlertedProjects
        self.totalExtendedProjects = object.totalExtendedProjects
        self.totalRegistedTodos = object.totalRegistedTodos
        self.totalFinishedTodos = object.totalFinishedTodos
        self.challengeStepStatus = object.challengeStepStatus
        self.myChallenges = object.mychallenges
    }
}

