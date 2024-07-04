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
    
    private init(){
        container = NSPersistentContainer(name: CoredataConfig.defaultModel)
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                Task {
                    await self.handleLocalStorageError(error: error)
                }
            }
        }
    }
    
    func saveContext() async -> Bool {
        let context = container.viewContext
        if context.hasChanges {
            do {
                try await context.perform {
                    try context.save()
                }
                return true
            } catch {
                print("[localStorage] Failed to save context: \(error)")
                return false
            }
        }
        print("[localStorage] Context change not detected")
        return false
    }
    
    func resetContext() async {
        let context = container.viewContext
        await context.perform {
            context.reset()
        }
    }

    func rebuildContext() async {
        let coordinator = container.persistentStoreCoordinator
        for store in coordinator.persistentStores {
            guard let storeURL = store.url else {
                print("[localStorage] Failed to get Store URL")
                await TopViewManager.shared.redirectToLoginView(
                    title: "Warning!",
                    message: "서비스의 동작이상이 감지되었습니다! 지속될 경우 재설치 해주세요"
                )
                return
            }
            do {
                try coordinator.destroyPersistentStore(at: storeURL, ofType: store.type, options: nil)
            } catch {
                print("[localStorage] Failed to truncate persistent: \(error)")
                await TopViewManager.shared.redirectToLoginView(
                    title: "Warning!",
                    message: "서비스의 동작이상이 감지되었습니다! 지속될 경우 재설치 해주세요"
                )
                return
            }
        }
        await retryLoadingLocalStorage()
    }
    
    // Shared method to initialize the persistent container
    private func initializePersistentContainer() async {
        container = NSPersistentContainer(name: CoredataConfig.defaultModel)
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                Task {
                    await self.handleLocalStorageError(error: error)
                }
            } else {
                print("[Coredata] Persistent container loaded successfully")
            }
        }
    }
}

//MARK: Error Handling

extension LocalStorageManager {
    
    private func retryLoadingLocalStorage() async {
        await initializePersistentContainer()
    }
    
    @MainActor
    private func handleLocalStorageError(error: NSError) {
        let alertController = UIAlertController(
            title: "Data Error",
            message: "Unable to load data. Please try again later.",
            preferredStyle: .alert
        )
        
        let retryAction = UIAlertAction(title: "Retry", style: .default) { _ in
            Task {
                await self.retryLoadingLocalStorage()
            }
        }

        alertController.addAction(retryAction)
        
        if let topVC = TopViewManager.shared.topViewController() {
            topVC.present(alertController, animated: true)
        } else {
            Task {
                await TopViewManager.shared.redirectToLoginView(
                    title: "Warning!",
                    message: "서비스의 동작이상이 감지되었습니다! 지속될 경우 재설치 해주세요"
                )
            }
        }
    }
}

//MARK: Test

extension LocalStorageManager {
    func testHandleLocalStorageError() {
        let error = NSError(domain: "TestErrorDomain", code: 9999, userInfo: [NSLocalizedDescriptionKey: "Test error description"])
        Task {
            await self.handleLocalStorageError(error: error)
        }
    }
}
