//
//  DeleteServerAndLocal.swift
//  teamplan
//
//  Created by 크로스벨 on 7/3/24.
//  Copyright © 2024 team1os. All rights reserved.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

final class DeleteSynchronize {
    
    // Local Storage
    private let userCD = UserServicesCoredata()
    private let statCD = StatisticsServicesCoredata()
    private let challengeCD = ChallengeServicesCoredata()
    private let accessLogCD = AccessLogServicesCoredata()
    private let projectCD = ProjectServicesCoredata()
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
    
    init(userId: String) {
        self.userId = userId
    }
    
    func deleteExecutor() async -> Bool {
        let isServerDataDeleted = await serverDeleteExecutor()
        let isLocalDataDeleted = await localDeleteExecutor()
        
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
        
        async let isUserDeleted = deleteUserAtServer(with: batch)
        async let isStatDeleted = deleteStatAtServer(with: batch)
        async let isChallengeDeleted = deleteChallengeAtServer(with: batch)
        async let isProjectDeleted = deleteProjectAtServer(with: batch)
        async let isAccessLogDeleted = deleteAccessLogAtServer(with: batch)
        async let isExtendLogDeleted = deleteExtendLogAtServer(with: batch)
        
        let results = await [
            isUserDeleted,
            isStatDeleted,
            isChallengeDeleted,
            isProjectDeleted,
            isAccessLogDeleted,
            isExtendLogDeleted
        ]
        
        if results.allSatisfy({$0}) {
            do {
                try await batch.commit()
                print("[DeleteSync] Successfully delete total data at server")
                return true
            } catch {
                print("[DeleteSync] Failed to commit delete batch")
                return false
            }
        } else {
            print("[DeleteSync] Failed to delete total data at server")
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
    
    private func localDeleteExecutor() async -> Bool {
        async let isUserDeleted = deleteUserAtLocal()
        async let isStatDeleted = deleteStatAtLocal()
        async let isChallengeDeleted = deleteChallengeAtLocal()
        async let isProjectDeleted = deleteProjectAtLocal()
        async let isAccessLogDeleted = deleteAccessLogAtLocal()
        async let isExtendLogDeleted = deleteExtendLogAtLocal()
        
        let results = await [
            isUserDeleted,
            isStatDeleted,
            isChallengeDeleted,
            isProjectDeleted,
            isAccessLogDeleted,
            isExtendLogDeleted
        ]
        
        if results.allSatisfy({$0}) {
            if await LocalStorageManager.shared.saveContext() {
                print("[DeleteSync] Successfully delete total data at local")
                return true
            } else {
                print("[DeleteSync] Failed to apply delete at local")
                return false
            }
        } else {
            print("[DeleteSync] Total data delete process failed")
            return false
        }
    }
    
    private func deleteUserAtLocal() async -> Bool {
        do {
            try userCD.deleteObject(with: userId)
            return true
        } catch {
            print("[DeleteSync] Failed to delete 'User' at local")
            return false
        }
    }
    
    private func deleteStatAtLocal() async -> Bool {
        do {
            try statCD.deleteObject(with: userId)
            return true
        } catch {
            print("[DeleteSync] Failed to delete 'Statistics' at local")
            return false
        }
    }
    
    private func deleteChallengeAtLocal() async -> Bool {
        do {
            try challengeCD.deleteObject(with: userId)
            return true
        } catch {
            print("[DeleteSync] Failed to delete 'Challenge' at local")
            return false
        }
    }
    
    private func deleteProjectAtLocal() async -> Bool {
        do {
            try projectCD.deleteObjectList(with: userId)
            return true
        } catch {
            print("[DeleteSync] Failed to delete 'Project' at local")
            return false
        }
    }
    
    private func deleteAccessLogAtLocal() async -> Bool {
        do {
            try accessLogCD.deleteObject(with: userId)
            return true
        } catch {
            print("[DeleteSync] Failed to delete 'AccessLog' at local")
            return false
        }
    }
    
    private func deleteExtendLogAtLocal() async -> Bool {
        do {
            try projectExtendCD.deleteObjects(with: userId)
            return true
        } catch {
            print("[DeleteSync] Failed to delete 'ProjectExtendLog' at local")
            return false
        }
    }
}
