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
    let util = Utilities()
    let cd = CoreDataManager.shared
    var context: NSManagedObjectContext {
        return cd.context
    }
    
    //================================
    // MARK: - Set Challenges
    //================================
    //##### Async/Await #####
    func setChallenges(reqChallenges: [ChallengeObject]) async throws {
        // Thread safe for multiple insert
        try context.performAndWait {
            for challenges in reqChallenges {
                setEntity(from: challenges)
            }
            
            // Store challenges to Coredata
            do {
                try context.save()
            } catch {
                print("(CoreData) Error Set Challenges : \(error)")
                throw ChallengeErrorCD.UnexpectedSetError
            }
        }
    }
    
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
        
        // get ChallengeEntities
        let fetchReq: NSFetchRequest<ChallengeEntity> = ChallengeEntity.fetchRequest()
        let reqChallenge = try self.context.fetch(fetchReq)
        
        // Convert Entity to Object
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
    func getChallenge(from chlgId: Int) throws -> ChallengeObject{
        // parameter setting
        let fetchReq: NSFetchRequest<ChallengeEntity> = ChallengeEntity.fetchRequest()
        
        // Request Query
        fetchReq.predicate = NSPredicate(format: "chlg_id == %@", chlgId)
        fetchReq.fetchLimit = 1
        
        guard let reqChallenge = try self.context.fetch(fetchReq).first,
              let chlgData = ChallengeObject(chlgEntity: reqChallenge) else {
            throw ChallengeErrorCD.InternalError
        }
        return chlgData
    }
    
    //================================
    // MARK: - update Challenge
    //================================
    func updateChallenge(from dto: ChallengeStatusDTO) async throws {
        
        // parameter setting
        let fetchReq: NSFetchRequest<ChallengeEntity> = ChallengeEntity.fetchRequest()
        
        // Request Query
        fetchReq.predicate = NSPredicate(format: "chlg_id == %d", dto.chlg_id)
        fetchReq.fetchLimit = 1
        
        do {
            guard let reqChallenge = try context.fetch(fetchReq).first else {
                throw ChallengeErrorCD.ChallengeRetrievalByIdentifierFailed
            }
            
            // update Challenge
            checkUpdateField(target: reqChallenge, with: dto)
 
            try context.save()
            
        } catch {
            // Eception Handling: Internal Error (Coredata)
            print("(CoreData) Error Update Challenge Status : \(error)")
            throw ChallengeErrorCD.UnexpectedUpdateError
        }
    }
    
    //##### Support #####
    private func checkUpdateField(target entity: ChallengeEntity, with dto: ChallengeStatusDTO){
        entity.chlg_selected = dto.chlg_selected ?? entity.chlg_selected
        entity.chlg_status = dto.chlg_status ?? entity.chlg_status
        entity.chlg_lock = dto.chlg_lock ?? entity.chlg_lock
        entity.chlg_selected_at = dto.chlg_selected_at ?? entity.chlg_selected_at
        entity.chlg_unselected_at = dto.chlg_unselected_at ?? entity.chlg_unselected_at
        entity.chlg_finished_at = dto.chlg_finished_at ?? entity.chlg_finished_at
    }
    
    //================================
    // MARK: - Delete Challenge
    //================================
    func deleteChallenges() async throws {
        
        let fetchReq: NSFetchRequest<ChallengeEntity> = ChallengeEntity.fetchRequest()
        
        try context.performAndWait {
            do {
                let reqChlgs = try self.context.fetch(fetchReq)
                
                // delete challenges
                for chlg in reqChlgs {
                    self.context.delete(chlg)
                }
                
                // save status
                try self.context.save()
                
            } catch {
                print("(CoreData) Error Delete Challenge : \(error)")
                throw ChallengeErrorCD.UnexpectedDeleteError
            }
        }
    }
}

//===============================
// MARK: - Exception
//===============================
enum ChallengeErrorCD: LocalizedError {
    case UnexpectedSetError
    case UnexpectedGetError
    case UnexpectedUpdateError
    case UnexpectedDeleteError
    case UnexpectedConvertError
    case ChallengeRetrievalByIdentifierFailed
    case MyChallengeNotFound
    case InternalError
    
    var errorDescription: String?{
        switch self {
        case .UnexpectedSetError:
            return "Coredata: There was an unexpected error while Set 'Challenge' details"
        case .UnexpectedGetError:
            return "Coredata: There was an unexpected error while Get 'Challenge' details"
        case .UnexpectedUpdateError:
            return "Coredata: There was an unexpected error while Update 'Challenge' details"
        case .UnexpectedDeleteError:
            return "Coredata: There was an unexpected error while Delete 'Challenge' details"
        case .UnexpectedConvertError:
            return "Coredata: There was an unexpected error while Convert 'Challenge' details"
        case .ChallengeRetrievalByIdentifierFailed:
            return "Coredata: Unable to retrieve 'Challenge' data using the provided identifier."
        case .MyChallengeNotFound:
            return "Coredata: MyChallenge Not Found"
        case .InternalError:
            return "Coredata: Internal Error Occurred while process 'Challenge' details"
        }
    }
}


