//
//  EraseService.swift
//  투두팡
//
//  Created by Crossbell on 9/19/24.
//  Copyright © 2024 team1os. All rights reserved.
//

import CoreData
import Foundation

final class EraseService {
    
    private let userCD: UserServicesCoredata
    private let statCD: StatisticsServicesCoredata
    private let challengeCD: ChallengeServicesCoredata
    private let accessLogCD: AccessLogServicesCoredata
    private let projectCD: ProjectServicesCoredata
    private let notifyCD: NotificationServicesCoredata
    private let storageManager: LocalStorageManager
    
    // properties
    private let userId: String
    
    init(userId: String) {
        self.userCD = UserServicesCoredata()
        self.statCD = StatisticsServicesCoredata()
        self.challengeCD = ChallengeServicesCoredata()
        self.accessLogCD = AccessLogServicesCoredata()
        self.projectCD = ProjectServicesCoredata()
        self.notifyCD = NotificationServicesCoredata()
        
        self.userId = userId
        
        self.storageManager = LocalStorageManager.shared
    }
    
    func eraseExecutor() -> Bool {
        let context = storageManager.context
        var results = [Bool]()
        
        return context.performAndWait{
            results = [
                deleteUserAtLocal(context),
                deleteStatAtLocal(context),
                deleteAccessLogAtLocal(context),
                deleteChallengeAtLocal(context),
                deleteProjectAtLocal(context),
            ]
    
            guard results.allSatisfy({$0}) else {
                print("[EraseSC] Local data delete process failed")
                return false
            }
            
            guard storageManager.saveContext() else {
                print("[EraseSC] Failed to apply delete at storage")
                return false
            }
            print("[EraseSC] Successfully delete total data at storage")
            return true
        }
    }
    
    private func deleteUserAtLocal(_ context: NSManagedObjectContext) -> Bool {
        do {
            try userCD.deleteObject(context: context, userId: userId)
            return true
        } catch {
            print("[EraseSC] Failed to delete 'User' at local")
            return false
        }
    }
    
    private func deleteStatAtLocal(_ context: NSManagedObjectContext) -> Bool {
        do {
            try statCD.deleteObject(context: context, userId: userId)
            return true
        } catch {
            print("[EraseSC] Failed to delete 'Statistics' at local")
            return false
        }
    }
    
    private func deleteChallengeAtLocal(_ context: NSManagedObjectContext) -> Bool {
        do {
            try challengeCD.deleteObject(context: context, userId: userId)
            return true
        } catch {
            print("[EraseSC] Failed to delete 'Challenge' at local")
            return false
        }
    }
    
    private func deleteProjectAtLocal(_ context: NSManagedObjectContext) -> Bool {
        do {
            try projectCD.deleteObjectList(context: context, with: userId)
            return true
        } catch {
            print("[EraseSC] Failed to delete 'Project' at local")
            return false
        }
    }
    
    private func deleteAccessLogAtLocal(_ context: NSManagedObjectContext) -> Bool {
        do {
            try accessLogCD.deleteObject(context: context, userId: userId)
            return true
        } catch {
            print("[EraseSC] Failed to delete 'AccessLog' at local")
            return false
        }
    }
    
    private func deleteNotifyAtLocal(_ context: NSManagedObjectContext) -> Bool {
        return notifyCD.deleteTotalObject(context, userId: userId)
    }
}
