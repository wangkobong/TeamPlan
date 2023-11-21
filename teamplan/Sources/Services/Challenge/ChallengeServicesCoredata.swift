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
    // MARK: - Set Challenges
    //================================
    func setChallenges(reqChallenges: [ChallengeObject]) throws {
        
        // Create Entity & Set Data
        for challenges in reqChallenges {
            setEntity(from: challenges)
        }
        try context.save()
    }
    // Support Function
    private func setEntity(from challenge: ChallengeObject) {
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
    // MARK: - Get Challenges
    //================================
    func getChallenges() throws -> [ChallengeObject] {
        
        // get Challenges
        let fetchReq: NSFetchRequest<ChallengeEntity> = ChallengeEntity.fetchRequest()
        let reqChallenge = try self.context.fetch(fetchReq)
        
        // Convert to Object Array
        let challengeData = reqChallenge.compactMap { ChallengeObject(chlgEntity: $0) }
        
        // Exception Handling: Convert
        if challengeData.count != reqChallenge.count {
            throw ChallengeErrorCD.UnexpectedConvertError
        }
        return challengeData
    }
    
    //================================
    // MARK: - Get Challenge
    //================================
    func getChallenge(from challengeId: Int) throws -> ChallengeObject{
        
        // parameter setting
        let fetchReq: NSFetchRequest<ChallengeEntity> = ChallengeEntity.fetchRequest()
        
        // Request Query
        fetchReq.predicate = NSPredicate(format: "chlg_id == %@", challengeId)
        fetchReq.fetchLimit = 1
        
        // Search Data
        guard let reqChallenge = try context.fetch(fetchReq).first else {
            throw ChallengeErrorCD.ChallengeRetrievalByIdentifierFailed
        }
        // Convert to Object & Get
        guard let challengeData = ChallengeObject(chlgEntity: reqChallenge) else {
            throw ChallengeErrorCD.UnexpectedConvertError
        }
        return challengeData
    }
    
    //================================
    // MARK: - update Challenge
    //================================
    func updateChallenge(from updatedChallenge: ChallengeStatusDTO) throws {
        
        // parameter setting
        let fetchReq: NSFetchRequest<ChallengeEntity> = ChallengeEntity.fetchRequest()
        
        // Request Query
        fetchReq.predicate = NSPredicate(format: "chlg_id == %d", updatedChallenge.chlg_id)
        fetchReq.fetchLimit = 1
        
        // Search Data
        guard let reqChallenge = try context.fetch(fetchReq).first else {
            throw ChallengeErrorCD.ChallengeRetrievalByIdentifierFailed
        }
        // Update Data
        checkUpdate(from: reqChallenge, to: updatedChallenge)
        try context.save()
    }
    // Support Function
    private func checkUpdate(from origin: ChallengeEntity, to updated: ChallengeStatusDTO) {
        origin.chlg_selected = updated.chlg_selected ?? origin.chlg_selected
        origin.chlg_status = updated.chlg_status ?? origin.chlg_status
        origin.chlg_lock = updated.chlg_lock ?? origin.chlg_lock
        origin.chlg_selected_at = updated.chlg_selected_at ?? origin.chlg_selected_at
        origin.chlg_unselected_at = updated.chlg_unselected_at ?? origin.chlg_unselected_at
        origin.chlg_finished_at = updated.chlg_finished_at ?? origin.chlg_finished_at
    }
    
    //================================
    // MARK: - Delete Challenges
    //================================
    func deleteChallenges() throws {
        
        // parameter setting
        let fetchReq: NSFetchRequest<ChallengeEntity> = ChallengeEntity.fetchRequest()
        
        // Search Data
        let reqChallenges = try self.context.fetch(fetchReq)
        
        // Delete Data
        for challenge in reqChallenges {
            context.delete(challenge)
        }
        try context.save()
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
