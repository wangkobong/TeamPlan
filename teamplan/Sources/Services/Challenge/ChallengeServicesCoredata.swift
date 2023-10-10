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
    //TODO: Exception Handling
    func getChallengeCoredata() async -> [ChallengeObject]{
        
        // parameter setting
        let fetchReq: NSFetchRequest<ChallengeEntity> = ChallengeEntity.fetchRequest()
        
        do{
            let chlgEntities = try context.fetch(fetchReq)
            return chlgEntities.map{ ChallengeObject(chlgEntity: $0) }
        } catch {
            print("Failed to fetch Challenges: \(error)")
            return []
        }
    }
    
    //================================
    // MARK: - Get MyChallenge
    //================================
    //TODO: Exception Handling
    func getMyChallengeCoredata() async -> [ChallengeObject]{
        
        // parameter setting
        let fetchReq: NSFetchRequest<ChallengeEntity> = ChallengeEntity.fetchRequest()
        
        // Request Query
        fetchReq.predicate = NSPredicate(format: "chlg_selected == %@", NSNumber(value: true))
        
        do{
            let chlgEntities = try context.fetch(fetchReq)
            return chlgEntities.map{ ChallengeObject(chlgEntity: $0) }
        } catch {
            print("Failed to fetch MyChallenges: \(error)")
            return []
        }
    }
    
    //================================
    // MARK: - Select MyChallenge (Update)
    //================================
    //TODO: Exception Handling
    func selectMyChallenge(chlg_id: Int, status: Bool) -> Bool {
        
        // parameter setting
        let fetchReq: NSFetchRequest<ChallengeEntity> = ChallengeEntity.fetchRequest()
        
        // Request Query
        fetchReq.predicate = NSPredicate(format: "chlg_id == %@", chlg_id)
        fetchReq.fetchLimit = 1
        
        do{
            // Get Challenge Entities
            let chlgEntities = try context.fetch(fetchReq)
            
            // Extract Entity by 'chlg_id'
            if let chlgEntity = chlgEntities.first {
                
                // update 'MyChallenge Selected' status
                chlgEntity.chlg_selected = status
                
                // update selected Date
                if(status == true){
                    chlgEntity.chlg_selected_at = Date()
                } else {
                    chlgEntity.chlg_unselected_at = Date()
                }
                
                // save update
                try context.save()
                
                // return status
                return true
                
            } else {
                print("No ChallengeEntity found with chlg_id: \(chlg_id)")
                return false
            }
        } catch {
            print("Failed to fetch or update ChallengeEntity: \(error)")
            return false
        }
    }
}
