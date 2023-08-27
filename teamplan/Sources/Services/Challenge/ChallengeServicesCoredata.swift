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
    var persistentContainer: NSPersistentContainer
    
    // StoreType Setting
    init(storeType: NSPersistentStore.StoreType){
        persistentContainer = NSPersistentContainer(name: "Coredata")
        
        let desc = NSPersistentStoreDescription()
        desc.type = storeType.rawValue
        persistentContainer.persistentStoreDescriptions = [desc]
        
        persistentContainer.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            } else {
                print("Succcessfully Load CoreData : \(storeDescription.description)")
            }
        })
    }
    
    // Container Handler
    lazy var managedObjectContext: NSManagedObjectContext = {
        return persistentContainer.viewContext
    }()
    
    
    //================================
    // MARK: - Get MyChallenge
    //================================
    func getMyChallengeCoredata() async -> [ChallengeObject]{
        
        // parameter setting
        let context: NSManagedObjectContext = managedObjectContext
        let fetchReq: NSFetchRequest<ChallengeEntity> = ChallengeEntity.fetchRequest()
        
        // Request Query
        fetchReq.predicate = NSPredicate(format: "chlg_selected == %@", NSNumber(value: true))
        
        // TODO: Exception Handling
        do{
            let chlgEntities = try context.fetch(fetchReq)
            return chlgEntities.map{ ChallengeObject(chlgEntity: $0) }
        } catch {
            print("Failed to fetch Challenges: \(error)")
            return []
        }
    }
}
