//
//  DeleteServerAndLocal.swift
//  teamplan
//
//  Created by 크로스벨 on 7/3/24.
//  Copyright © 2024 team1os. All rights reserved.
/*

import CoreData
import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

final class DeleteSynchronize {
    
    // Local Storage
    private let userCD = UserServicesCoredata()
    private let statCD = StatisticsServicesCoredata()
    private let challengeCD = ChallengeServicesCoredata()
    private let accessLogCD = AccessLogServicesCoredata()
    private let projectCD = ProjectExtendLogServicesCoredata()
    private let projectExtendCD = ProjectExtendLogServicesCoredata()
    
    // Server Storage
    private let userFS = UserServicesFirestore()
    private let statFS = StatisticsServicesFirestore()
    private let challengeFS = ChallengeServicesFirestore()
    private let accessLogFS = AccessLogServicesFirestore()
    private let projectFS = ProjectServicesFirestore()
    private let projectExtendFS = ProjectExtendLogServicesFirestore()
    
    // properties
    private let userId: String
    private let storageManager: LocalStorageManager
    
    init(userId: String) {
        self.userId = userId
        self.storageManager = LocalStorageManager.shared
    }
    
    func deleteExecutor() async -> Bool {
        let isServerDataDeleted = await serverDeleteExecutor()
        let isLocalDataDeleted = localDeleteExecutor()
        
        if isServerDataDeleted && isLocalDataDeleted {
            print("[DeleteSync] Successfully delete total data about user")
            return true
        } else {
            print("[DeleteSync] Failed to delete total data about user")
            return false
        }
    }
}

//MARK: Delete at Server

extension DeleteSynchronize {
    
    private func serverDeleteExecutor() async -> Bool {
        let batch = Firestore.firestore().batch()
        let tasks: [() async -> Bool] = [
            { await self.deleteUserAtServer(with: batch) },
            { await self.deleteStatAtServer(with: batch) },
            { await self.deleteChallengeAtServer(with: batch) },
            { await self.deleteProjectAtServer(with: batch) },
            { await self.deleteAccessLogAtServer(with: batch) },
            { await self.deleteExtendLogAtServer(with: batch) }
        ]
        for task in tasks {
            if await !task() {
                print("[DeleteSync] Failed to set userData at batch")
                return false
            }
        }
        do {
            try await batch.commit()
            print("[DeleteSync] Successfully delete total data at server")
            return true
        } catch {
            print("[DeleteSync] Failed to commit delete batch")
            return false
        }
    }
    
    // User
    private func deleteUserAtServer(with batch: WriteBatch) async -> Bool {
        await userFS.deleteDocs(with: userId, and: batch)
        return true
    }
    
    // Stat
    private func deleteStatAtServer(with batch: WriteBatch) async -> Bool {
        await statFS.deleteDocs(with: userId, and: batch)
        return true
    }
    
    // Challenge
    private func deleteChallengeAtServer(with batch: WriteBatch) async -> Bool {
        do {
            try await challengeFS.deleteStatusDocs(with: userId, and: batch)
            return true
        } catch {
            print("[DeleteSync] Failed to set 'challenge delete' at batch")
            return false
        }
    }
    
    // Project
    private func deleteProjectAtServer(with batch: WriteBatch) async -> Bool {
        do {
            try await projectFS.deleteDocs(with: userId, and: batch)
            return true
        } catch {
            print("[DeleteSync] Failed to set 'project delete' at batch")
            return false
        }
    }
    
    // AccessLog
    private func deleteAccessLogAtServer(with batch: WriteBatch) async -> Bool {
        do {
            try await accessLogFS.deleteDocs(with: userId, and: batch)
            return true
        } catch {
            print("[DeleteSync] Failed to set 'accessLog delete' at batch")
            return false
        }
    }
    
    // ProjectExtendLog
    private func deleteExtendLogAtServer(with batch: WriteBatch) async -> Bool {
        do {
            try await projectExtendFS.deleteDocs(with: userId, and: batch)
            return true
        } catch {
            print("[DeleteSync] Failed to set 'projectExtendLog delete' at batch")
            return false
        }
    }
}

//MARK: Delete At Local

extension DeleteSynchronize {
    
    private func localDeleteExecutor() -> Bool {
        let context = storageManager.context
        var results = [Bool]()
        
        return context.performAndWait{
            results = [
                deleteUserAtLocal(context: context),
                deleteStatAtLocal(context: context),
                deleteChallengeAtLocal(context: context),
                deleteProjectAtLocal(context: context),
                deleteAccessLogAtLocal(context: context),
                deleteExtendLogAtLocal(context: context)
            ]
            
            guard results.allSatisfy({$0}) else {
                print("[DeleteSync] Local data delete process failed")
                return false
            }
            
            guard storageManager.saveContext() else {
                print("[DeleteSync] Failed to apply delete at local")
                return false
            }
            return true
        }
    }
    
    private func deleteUserAtLocal(context: NSManagedObjectContext) -> Bool {
        do {
            try userCD.deleteObject(context: context, userId: userId)
            return true
        } catch {
            print("[DeleteSync] Failed to delete 'User' at local")
            return false
        }
    }
    
    private func deleteStatAtLocal(context: NSManagedObjectContext) -> Bool {
        do {
            try statCD.deleteObject(context: context, userId: userId)
            return true
        } catch {
            print("[DeleteSync] Failed to delete 'Statistics' at local")
            return false
        }
    }
    
    private func deleteChallengeAtLocal(context: NSManagedObjectContext) -> Bool {
        do {
            try challengeCD.deleteObject(context: context, userId: userId)
            return true
        } catch {
            print("[DeleteSync] Failed to delete 'Challenge' at local")
            return false
        }
    }
    
    private func deleteProjectAtLocal(context: NSManagedObjectContext) -> Bool {
        do {
            try projectCD.deleteObjects(context: context, with: userId)
            return true
        } catch {
            print("[DeleteSync] Failed to delete 'Project' at local")
            return false
        }
    }
    
    private func deleteAccessLogAtLocal(context: NSManagedObjectContext) -> Bool {
        do {
            try accessLogCD.deleteObject(context: context, userId: userId)
            return true
        } catch {
            print("[DeleteSync] Failed to delete 'AccessLog' at local")
            return false
        }
    }
    
    private func deleteExtendLogAtLocal(context: NSManagedObjectContext) -> Bool {
        do {
            try projectExtendCD.deleteObjects(context: context, with: userId)
            return true
        } catch {
            print("[DeleteSync] Failed to delete 'ProjectExtendLog' at local")
            return false
        }
    }
}
 
*/
