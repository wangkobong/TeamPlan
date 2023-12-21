//
//  ChallengeServicesCoredata.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/08/26.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation
import CoreData

final class ChallengeServicesCoredata{
    
    //================================
    // MARK: - Parameter Setting
    //================================
    let cd = CoreDataManager.shared
    var context: NSManagedObjectContext {
        return cd.context
    }
    
    //================================
    // MARK: - Set Challenge
    //================================
    func setChallenges(with array: [ChallengeObject]) throws {
        
        // Create Entity & Set Data
        for challenge in array {
            setEntity(with: challenge)
        }
        try context.save()
    }
    // Support Function
    private func setEntity(with challenge: ChallengeObject) {
        let chlgEntity = ChallengeEntity(context: context)
        
        chlgEntity.chlg_id = Int32(challenge.chlg_id)
        chlgEntity.chlg_user_id = challenge.chlg_user_id
        chlgEntity.chlg_type = Int32(challenge.chlg_type.rawValue)
        chlgEntity.chlg_title = challenge.chlg_title
        chlgEntity.chlg_desc = challenge.chlg_desc
        chlgEntity.chlg_goal = Int32(challenge.chlg_goal)
        chlgEntity.chlg_reward = Int32(challenge.chlg_reward)
        chlgEntity.chlg_step = Int32(challenge.chlg_step)
        chlgEntity.chlg_selected = challenge.chlg_selected
        chlgEntity.chlg_status = challenge.chlg_status
        chlgEntity.chlg_lock = challenge.chlg_lock
        chlgEntity.chlg_selected_at = challenge.chlg_selected_at
        chlgEntity.chlg_unselected_at = challenge.chlg_unselected_at
        chlgEntity.chlg_finished_at = challenge.chlg_finished_at
    }
    
    //================================
    // MARK: - Get Challenge
    //================================
    // Single
    func getChallenge(with challengeId: Int) throws -> ChallengeObject{
        
        // Fetch Entity
       let entity = try fetchEntity(with: challengeId)
        
        // Convert to Object & Get
        guard let object = ChallengeObject(chlgEntity: entity) else {
            throw ChallengeErrorCD.UnexpectedConvertError
        }
        return object
    }
    
    // Array
    func getChallenges() throws -> [ChallengeObject] {
        
        // Fetch EntityArray
        let entities = try fetchEntities()
        
        // Convert to Object Array
        let array = entities.compactMap { ChallengeObject(chlgEntity: $0) }
        
        // Exception Handling: Convert
        if array.count != entities.count {
            throw ChallengeErrorCD.UnexpectedConvertError
        }
        return array
    }

    
    //================================
    // MARK: - update Challenge
    //================================
    func updateChallenge(with dto: ChallengeStatusDTO) throws {
        
        // Fetch Entity
        let entity = try fetchEntity(with: dto.chlg_id)
        
        // Update Data
        checkUpdate(from: entity, to: dto)
        try context.save()
    }
    // Support Function
    private func checkUpdate(from origin: ChallengeEntity, to updated: ChallengeStatusDTO) {
        origin.chlg_selected = updated.chlg_selected
        origin.chlg_status = updated.chlg_status
        origin.chlg_lock = updated.chlg_lock
        origin.chlg_selected_at = updated.chlg_selected_at
        origin.chlg_unselected_at = updated.chlg_unselected_at
        origin.chlg_finished_at = updated.chlg_finished_at
    }
    
    //================================
    // MARK: - Delete Challenges
    //================================
    func deleteChallenges() throws {
        
        // parameter setting
        let entities = try fetchEntities()
        
        // Delete Data
        for challenge in entities {
            context.delete(challenge)
        }
        try context.save()
    }
    
    //================================
    // MARK: - Support Function
    //================================
    // Signle Entity
    private func fetchEntity(with challengeId: Int) throws -> ChallengeEntity {
        
        // parameter setting
        let fetchReq: NSFetchRequest<ChallengeEntity> = ChallengeEntity.fetchRequest()
        
        // Request Query
        fetchReq.predicate = NSPredicate(format: "chlg_id == %@", challengeId)
        fetchReq.fetchLimit = 1
        
        // Search Data
        guard let entity = try context.fetch(fetchReq).first else {
            throw ChallengeErrorCD.ChallengeRetrievalByIdentifierFailed
        }
        return entity
    }
    
    // Array Entity
    private func fetchEntities() throws -> [ChallengeEntity] {
        
        // parameter setting
        let fetchReq: NSFetchRequest<ChallengeEntity> = ChallengeEntity.fetchRequest()
        
        // Search Data
        let entities = try self.context.fetch(fetchReq)
        return entities
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
