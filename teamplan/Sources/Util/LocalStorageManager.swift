//
//  LocalStorageManager.swift
//  teamplan
//
//  Created by 크로스벨 on 6/25/24.
//  Copyright © 2024 team1os. All rights reserved.
//

import UIKit
import CoreData
import Foundation

enum CoredataConfig {
    static let defaultModel = "Coredata"
}

final class LocalStorageManager {
    static let shared = LocalStorageManager()
    var container: NSPersistentContainer
    var context: NSManagedObjectContext {
        return container.viewContext
    }
    
    private init() {
        container = NSPersistentContainer(name: CoredataConfig.defaultModel)
        loadPersistentStore()
    }
    
    private func loadPersistentStore() {
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                Task {
                    print("[localStorage] Persistent store loading error: \(error), \(error.userInfo)")
                    await self.handlePersistentStoreError(error: error)
                }
            }
        }
    }
    
    func saveContext() -> Bool {
        if context.hasChanges {
            do {
                try self.context.save()
                return true
            } catch {
                print("[localStorage] Failed to save context: \(error)")
                self.context.rollback()
                return false
            }
        }
        return true
    }
    
    // MARK: Background
    
    func createBackgroundContext() -> NSManagedObjectContext {
        let backgroundContext = container.newBackgroundContext()
        backgroundContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return backgroundContext
    }
    
    func saveBackgroundContext(_ context: NSManagedObjectContext) -> Bool {
        if context.hasChanges {
            print("[localStorage] Background context change detected")
            do {
                try context.save()
                return true
            } catch {
                print("[localStorage] Failed to save background context: \(error)")
                context.rollback()
                return false
            }
        }
        print("[localStorage] Background context change not detected")
        return true
    }
}

//MARK: Error Handling

extension LocalStorageManager {
    
    @MainActor
    private func handlePersistentStoreError(error: NSError) {
        print("[localStorage] Error while loading persistent store: \(error.localizedDescription)")
        
        let alertController = UIAlertController(
            title: "Data Error",
            message: "An error occurred while loading data. Please restart the app.",
            preferredStyle: .alert
        )
        let restartAction = UIAlertAction(title: "Restart", style: .default) { _ in
            exit(0)
        }
        alertController.addAction(restartAction)
        
        if let topVC = TopViewManager.shared.topViewController() {
            topVC.present(alertController, animated: true)
        }
    }
}
