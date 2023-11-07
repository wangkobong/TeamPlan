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
    //##### Result #####
    func getChallenges(result: @escaping(Result<[ChallengeObject], Error>) -> Void) {
        
        // parameter setting
        let fetchReq: NSFetchRequest<ChallengeEntity> = ChallengeEntity.fetchRequest()
        
        context.perform {
            do{
                let reqChlg = try self.context.fetch(fetchReq)
                
                // extract challenges
                let chlgData = reqChlg.compactMap { ChallengeObject(chlgEntity: $0) }
                
                // Exception Handling: Convert
                if chlgData.count != reqChlg.count {
                    return result(.failure(ChallengeErrorCD.UnexpectedConvertError))
                }
                return result(.success(chlgData))
                
                // Exception Handling: Internal Error
            } catch {
                print("(CoreData) Error Get Challenges : \(error)")
                return result(.failure(ChallengeErrorCD.InternalError))
            }
        }
    }
    
    //##### Result #####
    func getChallenge(chlgID: Int,
                      result: @escaping(Result<ChallengeObject, Error>) -> Void) {
        
        // parameter setting
        let fetchReq: NSFetchRequest<ChallengeEntity> = ChallengeEntity.fetchRequest()
        
        // Request Query
        fetchReq.predicate = NSPredicate(format: "chlg_id == %@", chlgID)
        fetchReq.fetchLimit = 1
        
        // Search Challenge
        context.perform {
            do{
                guard let reqChlg = try self.context.fetch(fetchReq).first else {
                    return result(.failure(ChallengeErrorCD.ChallengeRetrievalByIdentifierFailed))
                }
                
                guard let chlgData = ChallengeObject(chlgEntity: reqChlg) else {
                    return result(.failure(ChallengeErrorCD.UnexpectedConvertError))
                }
                return result(.success(chlgData))
                
            } catch {
                print("(CoreData) Error Get Challenge : \(error)")
                return result(.failure(ChallengeErrorCD.InternalError))
            }
        }
    }
    
    //##### Result #####
    func getMyChallenge(selected: [Int],
                                result: @escaping(Result<[ChallengeObject], Error>) -> Void) {
        
        var myChlg: [ChallengeObject] = []
        
        // Search MyChallenge
        for chlgID in selected {
            getChallenge(chlgID: chlgID) { response in
                switch response {
                    
                // Successfully Found MyChallenge
                case .success(let chlg):
                    myChlg.append(chlg)
                    
                // Failed to Found MyChallenge
                case .failure(let error):
                    print("(CoreData) Error Get MyChallenge : \(error)")
                    return result(.failure(error))
                }
            }
        }
        return result(.success(myChlg))
    }
    
    //================================
    // MARK: - update Challenge
    //================================
    //TODO: Exception Handling
    func updateChallengeStatus(updatedChallenge: ChallengeStatusReqDTO,
                           result: @escaping(Result<Bool, Error>) -> Void) {
        
        // parameter setting
        let fetchReq: NSFetchRequest<ChallengeEntity> = ChallengeEntity.fetchRequest()
        
        // Request Query
        fetchReq.predicate = NSPredicate(format: "chlg_id == %d", updatedChallenge.chlg_id)
        fetchReq.fetchLimit = 1
        
        do{
            // Get Challenge Entities
            guard let reqChlg = try context.fetch(fetchReq).first else {
                throw ChallengeErrorCD.ChallengeRetrievalByIdentifierFailed
            }
            
            // update Challenge
            var isUpdated = false
            
            isUpdated = util.updateFieldIfNeeded(&reqChlg.chlg_step, newValue: Int32(updatedChallenge.chlg_step)) || isUpdated
            isUpdated = util.updateFieldIfNeeded(&reqChlg.chlg_selected, newValue: updatedChallenge.chlg_selected) || isUpdated
            isUpdated = util.updateFieldIfNeeded(&reqChlg.chlg_status, newValue: updatedChallenge.chlg_status) || isUpdated
            isUpdated = util.updateFieldIfNeeded(&reqChlg.chlg_lock, newValue: updatedChallenge.chlg_lock) || isUpdated
            
            if isUpdated {
                try context.save()
            }

        } catch {
            // Eception Handling: Internal Error (Coredata)
            print("(CoreData) Error Update Challenge Status : \(error)")
            return result(.failure(ChallengeErrorCD.UnexpectedUpdateError))
        }
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


