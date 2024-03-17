//
//  CoredataController.swift
//  teamplan
//
//  Created by 크로스벨 on 3/15/24.
//  Copyright © 2024 team1os. All rights reserved.
//

import CoreData

protocol CoredataProtocol {
    var container: NSPersistentContainer { get }
    var context: NSManagedObjectContext { get }
}

enum CoredataConfig {
    static let defaultModel = "Coredata"
}

final class CoredataController: CoredataProtocol {
    // only initialize when it needed
    lazy var container: NSPersistentContainer = {
        let container = NSPersistentContainer(name: CoredataConfig.defaultModel)
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                fatalError("Unable to load persistent stores: \(error)")
            }
        }
        return container
    }()
    
    var context: NSManagedObjectContext {
        return container.viewContext
    }
}
