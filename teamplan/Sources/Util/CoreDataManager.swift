//
//  CoreDataManager.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/10/10.
//  Copyright © 2023 team1os. All rights reserved.
//

import CoreData
import Foundation

final class CoreDataManager{
    
    static let shared = CoreDataManager()
    var container: NSPersistentContainer
    var context: NSManagedObjectContext {
        return container.viewContext
    }
    
    // Load Coredata
    private init(){
        container = NSPersistentContainer(name: "Coredata")
        container.loadPersistentStores{ storeDescription, error in
            if let error = error as NSError? {
                fatalError("### Failed to load PersistentContainer\n \(error), \(error.userInfo)")
            }
        }
    }
}
