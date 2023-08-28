//
//  ProjectServicesCoredata.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/08/25.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation
import CoreData

final class ProjectServicesCoredata{
    
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
    // MARK: - Get Project
    //================================
    func getProjectCoredata() async -> [ProjectObject] {
        
        let context: NSManagedObjectContext = managedObjectContext
        let fetchReq: NSFetchRequest<ProjectEntity> = ProjectEntity.fetchRequest()
        
        do{
            let projectEntities = try context.fetch(fetchReq)
            return projectEntities.map{ ProjectObject(projectEntity: $0 )}
        } catch {
            print("Failed to fetch projects: \(error)")
            return []
        }
    }
}
