//
//  ChallengeServicesCoredata.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/08/26.
//  Copyright © 2023 team1os. All rights reserved.
//

import CoreData
import Foundation

final class ChallengeServicesCoredata{
    
    //================================
    // MARK: - Parameter
    //================================
    let util = Utilities()
    let cm = CoreDataManager.shared
    var context: NSManagedObjectContext {
        return cm.context
    }
}

//================================
// MARK: - Main Function
//================================
extension ChallengeServicesCoredata{
    
    //--------------------
    // Set
    //--------------------
    func setChallenges(with array: [ChallengeObject]) throws {
        // create & set entity
        for challenge in array {
            setEntity(with: challenge)
        }
        try context.save()
    }
    
    //--------------------
    // Get
    //--------------------
    // Single
    func getChallenge(with challengeId: Int, owner userId: String) throws -> ChallengeObject{
        // fetch entity
       let entity = try fetchEntity(with: challengeId, onwer: userId)
        // convert & return
        guard let object = ChallengeObject(chlgEntity: entity) else {
            throw ChallengeErrorCD.UnexpectedConvertError
        }
        return object
    }
    // Array
    func getChallenges(onwer userId: String) throws -> [ChallengeObject] {
        // fetch entities
        let entities = try fetchEntities(owner: userId)
        // convert & return
        let array = entities.compactMap { ChallengeObject(chlgEntity: $0) }
        if array.count != entities.count {
            throw ChallengeErrorCD.UnexpectedConvertError
        }
        return array
    }
    
    //--------------------
    // Update
    //--------------------
    func updateChallenge(with dto: ChallengeUpdateDTO) throws {
        // fetch entity
        let entity = try fetchEntity(with: dto.challengeId, onwer: dto.userId)
        // update & apply
        if checkUpdate(from: entity, to: dto) {
            try context.save()
        }
    }
    
    //--------------------
    // Update
    //--------------------
    func deleteChallenges(with userId: String) throws {
        // fetch entities
        let entities = try fetchEntities(owner: userId)
        // delete & apply
        for challenge in entities {
            context.delete(challenge)
        }
        try context.save()
    }
    
    //================================
    // MARK: - Support Function
    //================================
    // Signle Entity
    private func fetchEntity(with challengeId: Int, onwer userId: String) throws -> ChallengeEntity {
        // parameter setting
        let fetchReq: NSFetchRequest<ChallengeEntity> = ChallengeEntity.fetchRequest()
        // reqeust query
        fetchReq.predicate = NSPredicate(format: "chlg_id == %d AND chlg_user_id == %@", challengeId, userId)
        fetchReq.fetchLimit = 1
        // search data
        guard let entity = try context.fetch(fetchReq).first else {
            throw ChallengeErrorCD.ChallengeRetrievalByIdentifierFailed
        }
        return entity
    }
    
    // Array Entity
    private func fetchEntities(owner userId: String) throws -> [ChallengeEntity] {
        // parameter setting
        let fetchReq: NSFetchRequest<ChallengeEntity> = ChallengeEntity.fetchRequest()
        // reqeust query
        fetchReq.predicate = NSPredicate(format: "chlg_user_id == %@", userId)
        fetchReq.fetchLimit = challengeCount
        // search data
        let entities = try self.context.fetch(fetchReq)
        if entities.count != challengeCount {
            throw ChallengeErrorCD.ChallengeRetrievalByIdentifierFailed
        }
        return entities
    }
}

//================================
// MARK: - Support Function
//================================
extension ChallengeServicesCoredata{
    
    // Set
    private func setEntity(with object: ChallengeObject) {
        let entity = ChallengeEntity(context: context)
        
        entity.chlg_id = Int32(object.chlg_id)
        entity.chlg_user_id = object.chlg_user_id
        entity.chlg_type = Int32(object.chlg_type.rawValue)
        entity.chlg_title = object.chlg_title
        entity.chlg_desc = object.chlg_desc
        entity.chlg_goal = Int32(object.chlg_goal)
        entity.chlg_reward = Int32(object.chlg_reward)
        entity.chlg_step = Int32(object.chlg_step)
        entity.chlg_selected = object.chlg_selected
        entity.chlg_status = object.chlg_status
        entity.chlg_lock = object.chlg_lock
        entity.chlg_selected_at = object.chlg_selected_at
        entity.chlg_unselected_at = object.chlg_unselected_at
        entity.chlg_finished_at = object.chlg_finished_at
    }
    
    // Update
    private func checkUpdate(from origin: ChallengeEntity, to updated: ChallengeUpdateDTO) -> Bool {
        var isUpdated = false
        
        if let newSelected = updated.newSelected {
            isUpdated = util.updateFieldIfNeeded(&origin.chlg_selected, newValue: newSelected)
        }
        if let newStatus = updated.newStatus {
            isUpdated = util.updateFieldIfNeeded(&origin.chlg_status, newValue: newStatus)
        }
        if let newLock = updated.newLock {
            isUpdated = util.updateFieldIfNeeded(&origin.chlg_lock, newValue: newLock)
        }
        if let newSelectedAt = updated.newSelectedAt {
            isUpdated = util.updateFieldIfNeeded(&origin.chlg_selected_at, newValue: newSelectedAt)
        }
        if let newUnSelectedAt = updated.newUnSelectedAt{
            isUpdated = util.updateFieldIfNeeded(&origin.chlg_unselected_at, newValue: newUnSelectedAt)
        }
        if let newFinishedAt = updated.newFinishedAt {
            isUpdated = util.updateFieldIfNeeded(&origin.chlg_finished_at, newValue: newFinishedAt)
        }
        return isUpdated
    }
}

//===============================
// MARK: - Exception
//===============================
enum ChallengeErrorCD: LocalizedError {
    case UnexpectedConvertError
    case ChallengeRetrievalByIdentifierFailed
    
    var errorDescription: String?{
        switch self {
        case .UnexpectedConvertError:
            return "Coredata: There was an unexpected error while Convert 'Challenge' details"
        case .ChallengeRetrievalByIdentifierFailed:
            return "Coredata: Unable to retrieve 'Challenge' data using the provided identifier."
        }
    }
}
