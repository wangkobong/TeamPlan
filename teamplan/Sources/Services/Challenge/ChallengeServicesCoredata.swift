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
    // MARK: - CoreData Setting
    //================================
    let cd = CoreDataManager.shared
    var context: NSManagedObjectContext {
        return cd.context
    }
    
    //================================
    // MARK: - Get Challenge
    //================================
    func getChallengeCoredata(identifier: String,
                              result: @escaping(Result<[ChallengeObject], Error>) -> Void) {
        
        // parameter setting
        let fetchReq: NSFetchRequest<ChallengeEntity> = ChallengeEntity.fetchRequest()
        
        // Request Query
        fetchReq.predicate = NSPredicate(format: "chlg_user_id == %@", identifier)
        
        do{
            let fetchChlg = try context.fetch(fetchReq)
            
            // Exception Handling: Identifier
            if fetchChlg.isEmpty {
                return result(.failure(ChallengeCDError.IdentifierFetchFailed))
            }
            
            // extract challenges
            let reqChlg = fetchChlg.map{ ChallengeObject(chlgEntity: $0) }
            return result(.success(reqChlg))
            
        // Eception Handling: Unknown
        } catch {
            return result(.failure(ChallengeCDError.GetFailed))
        }
    }
    
    //================================
    // MARK: - Get MyChallenge
    //================================
    func getMyChallengeCoredata(identifier: String,
                                result: @escaping(Result<[ChallengeObject], Error>) -> Void) {
        
        // Get ChallengeList
        self.getChallengeCoredata(identifier: identifier) { cdResult in
            switch cdResult {
            case .success(let reqChlg):
                
                // extract MyChallenge
                let myChlg = reqChlg.filter { $0.chlg_selected == true }
                
                // Exception Handling: noMyChallenge
                if myChlg.isEmpty {
                    return result(.failure(ChallengeCDError.noMyChallenge))
                }
                return result(.success(myChlg))
            
            // Exception Handling: Failed to get ChallengeList
            case .failure(let error):
                return result(.failure(error))
            }
        }
    }
    
    //================================
    // MARK: - select MyChallenge
    //================================
    //TODO: Exception Handling
    func selectMyChallenge(identifier: String, chlg_id: Int, status: Bool,
                           result: @escaping(Result<Bool, Error>) -> Void) {
        
        // parameter setting
        let fetchReq: NSFetchRequest<ChallengeEntity> = ChallengeEntity.fetchRequest()
        
        // Request Query
        fetchReq.predicate = NSPredicate(format: "chlg_id == %d", chlg_id)
        fetchReq.fetchLimit = 1
        
        do{
            // Get Challenge Entities
            let fetchChlg = try context.fetch(fetchReq)
            
            guard let reqChlg = fetchChlg.first else {
                return result(.failure(ChallengeCDError.chlgIdFetchFailed))
            }
            
            // update 'MyChallenge Selected' status
            reqChlg.chlg_selected = status
            
            // update selected Date
            if(status == true){
                reqChlg.chlg_selected_at = Date()
            } else {
                reqChlg.chlg_unselected_at = Date()
            }
            
            try context.save()
            return result(.success(true))
        } catch {
            return result(.failure(ChallengeCDError.UpdateFailed))
        }
    }
    
    //===============================
    // MARK: - Exception
    //===============================
    enum ChallengeCDError: LocalizedError {
        case noMyChallenge
        case chlgIdFetchFailed
        case IdentifierFetchFailed
        case SetFailed
        case GetFailed
        case UpdateFailed
        
        var errorDescription: String?{
            switch self {
            case .noMyChallenge:
                return "No Selected Challenge for MyChallenge"
            case .chlgIdFetchFailed:
                return "Failed to Fetch Challenge by ChallengeID"
            case .IdentifierFetchFailed:
                return "Failed to Fetch Challenge by identifier"
            case .SetFailed:
                return "Failed to Set Challenge at CoreData"
            case .GetFailed:
                return "Failed to Get Challenge for Unknown reason"
            case .UpdateFailed:
                return "Failed to Update Challenge at CoreData"
            }
        }
    }
}
