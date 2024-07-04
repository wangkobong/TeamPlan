//
//  SyncServerWithLocal.swift
//  teamplan
//
//  Created by 크로스벨 on 1/10/24.
//  Copyright © 2024 team1os. All rights reserved.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

enum SyncType: String {
    case weekly = "Weekly"
    case monthly = "Monthly"
    case quarterly = "Quarterly"
}

final class ServerSynchronize {
    
    private let util = Utilities()
    
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
    
    private var updatedProject = Set<Int>()
    
    // shared Properties
    private var userId: String
    
    // Local Properties
    private var localUser: UserObject
    private var localStat : StatisticsObject
    private var localAccessLogHead : Int
    private var localAccessLogs : [AccessLog]
    private var localChallenges : [ChallengeObject]
    private var localUpdateNeedChallengeIds : [Int]
    private var localProjects : [ProjectObject]
    private var localUploadNeedProjectIds : [Int]
    private var localUploadNeedProjects : [ProjectObject]
    private var localUpdateNeedProjectIds : [Int]
    private var localUpdateNeedProjects : [Int : ProjectObject]
    private var localProjectIds : [Int]
    private var localProjectLog : [Int : [ProjectExtendLog]]
    
    // Server Properties
    private var batch : WriteBatch
    private var serverUser: UserObject
    private var serverStat : StatisticsObject
    private var serverProjectIds = Set<Int>()
    private var serverProjects : [Int : ProjectObject]
    
    
    init(with userId: String) {
        self.userId = userId
        self.localUser = UserObject()
        self.localStat = StatisticsObject()
        self.localAccessLogHead = 0
        self.localAccessLogs = []
        self.localUpdateNeedChallengeIds = []
        self.localChallenges = []
        self.localProjectIds = []
        self.localProjects = []
        self.localUploadNeedProjectIds = []
        self.localUploadNeedProjects = []
        self.localUpdateNeedProjectIds = []
        self.localUpdateNeedProjects = [:]
        self.localProjectLog = [:]
        
        self.batch = Firestore.firestore().batch()
        self.serverUser = UserObject()
        self.serverStat = StatisticsObject()
        self.serverProjects = [:]
    }
    
    // MARK: - Sync Executor
    func syncExecutor(_ type: SyncType, with syncDate: Date) async -> Bool {
         var results: [Bool] = []
        
        switch type {
        case .weekly:
            async let isLocalDataFetched = localFetchExecutor(.weekly, with: syncDate)
            async let isServerDataFetched = serverFetchExecutor(.weekly)
            
            results = await [isLocalDataFetched, isServerDataFetched]
            
            if results.allSatisfy({$0}) {
                await preprocessExecutor(.weekly, with: syncDate)
                let isServerUpdated = await serverUpdateExecutor(.weekly, with: syncDate)

                if isServerUpdated {
                    return await localUpdateExecutor(.weekly, with: syncDate)
                } else {
                    return false
                }
            } else {
                return false
            }
            
        case .monthly:
            async let isLocalDataFetched = localFetchExecutor(.monthly, with: syncDate)
            async let isServerDataFetched = serverFetchExecutor(.monthly)
            
            results = await [isLocalDataFetched, isServerDataFetched]
            
            if results.allSatisfy({$0}) {
                await preprocessExecutor(.monthly, with: syncDate)
                let isServerUpdated = await serverUpdateExecutor(.monthly, with: syncDate)
                
                if isServerUpdated {
                    return await localUpdateExecutor(.monthly, with: syncDate)
                } else {
                    return false
                }
            } else {
                return false
            }
            
        case .quarterly:
            async let isLocalDataFetched = localFetchExecutor(.quarterly, with: syncDate)
            async let isServerDataFetched = serverFetchExecutor(.quarterly)
            
            results = await [isLocalDataFetched, isServerDataFetched]
            
            if results.allSatisfy({$0}) {
                await preprocessExecutor(.quarterly, with: syncDate)
                let isProjectLogFetched = await fetchProjectLogFromLocal()
                print(localProjectLog)
                let isServerUpdated = await serverUpdateExecutor(.quarterly, with: syncDate)
                
                if isServerUpdated {
                    return await localUpdateExecutor(.monthly, with: syncDate)
                } else {
                    return false
                }
            } else {
                return false
            }
        }
    }
}

// MARK: - Fetch Local Data

extension ServerSynchronize {
    
    private func localFetchExecutor(_ type: SyncType, with syncDate: Date) async -> Bool {
        var results: [Bool] = []
        
        switch type {
        case .weekly:
            async let isLocalUserFetch = fetchUserFromLocal()
            async let isLocalStatFetch = fetchStatFromLocal()
            async let isLocalAccessLogFetch = fetchAccessLogFromLocal()
            
            results = await [isLocalUserFetch, isLocalStatFetch, isLocalAccessLogFetch]
            
        case .monthly:
            async let isLocalChallengeFetch = fetchChallengeFromLocal(with: syncDate)
            async let isLocalProjectFetch = fetchProjectFromLocal()
            
            results = await [isLocalChallengeFetch, isLocalProjectFetch]
            
        case .quarterly:
            async let isLocalUserFetch = fetchUserFromLocal()
            async let isLocalAccessLogFetch = fetchAccessLogFromLocal()
            async let isLocalProjectFetch = fetchProjectFromLocal()
            
            results = await [isLocalUserFetch, isLocalAccessLogFetch, isLocalProjectFetch]
        }
        if results.allSatisfy({$0}){
            print("[ServerSync] Successfully fetch local data")
            return true
        } else {
            print("[ServerSync] Failed to fetch local data")
            return false
        }
    }
    
    // User
    private func fetchUserFromLocal() async -> Bool {
        do {
            self.localUser = try userCD.getObject(with: userId)
            return true
        } catch {
            print("[ServerSync] Failed to fetch UserData from storage")
            return false
        }
    }
    
    // Stat
    private func fetchStatFromLocal() async -> Bool {
        do {
            self.localStat = try statCD.getObject(with: userId)
            return true
        } catch {
            print("[ServerSync] Failed to fetch StatData from storage")
            return false
        }
    }
    
    // AccessLog
    private func fetchAccessLogFromLocal() async -> Bool {
        do {
            self.localAccessLogs = try accessLogCD.getFullObjects(with: userId)
            return true
        } catch {
            print("[ServerSync] Failed to fetch AccessLog from storage")
            return false
        }
    }
    
    // Challenge
    private func fetchChallengeFromLocal(with syncDate: Date) async -> Bool {
        do {
            self.localChallenges = try await challengeCD.getTartgetObjects(with: userId, syncDate: syncDate)
            return true
        } catch {
            print("[ServerSync] Failed to fetch Challenges from storage")
            return false
        }
    }
    
    // Project
    private func fetchProjectFromLocal() async -> Bool {
        do {
            self.localProjects = try projectCD.getValidObjects(with: userId)
            return true
        } catch {
            print("[ServerSync] Failed to fetch ProjectInfo from storage")
            return false
        }
    }
    
    // ProjectLog
    private func fetchProjectLogFromLocal() async -> Bool {
        do {
            for projectLogId in localProjectIds {
                let logs = try projectExtendCD.getObjects(with: projectLogId, and: userId)
                print("[ServerSync] ProjectLog that need to upload : \(logs.count)")
                self.localProjectLog[projectLogId] = logs
            }
            return true
        } catch {
            print("[ServerSync] Failed to fetch ProjectExtendLog from storage")
            return false
        }
    }
}

// MARK: - Fetch Server Data

extension ServerSynchronize {
    
    private func serverFetchExecutor(_ type: SyncType) async -> Bool {
        var results: [Bool] = []
        
        switch type {
        case .weekly, .quarterly:
            async let isServerUserFetch = fetchUserFromServer()
            async let isServerStatFetch = fetchStatFromServer()
            
            results = await [isServerUserFetch, isServerStatFetch]
        case .monthly:
            results.append(await fetchProjectsFromServer())
        }
        return results.allSatisfy{$0}
    }
    
    private func fetchUserFromServer() async -> Bool {
        do {
            self.serverUser = try await userFS.getDocs(with: userId)
            print("[ServerSync] Successfully fetch UserData from server")
            return true
        } catch {
            print("[ServerSync] Failed to fetch UserData from server")
            return false
        }
    }
    
    private func fetchStatFromServer() async -> Bool {
        do {
            self.serverStat = try await statFS.getDocs(with: userId)
            print("[ServerSync] Successfully fetch StatData from server")
            return true
        } catch {
            print("[ServerSync] Failed to fetch StatData from server")
            return false
        }
    }
    
    private func fetchProjectsFromServer() async -> Bool {
        do {
            let projectList = try await projectFS.getDocsList(with: userId)
            for project in projectList {
                self.serverProjectIds.insert(project.projectId)
                self.serverProjects[project.projectId] = project
            }
            print("[ServerSync] Successfully fetch ProjectData from server: \(projectList.count)")
            return true
        } catch {
            print("[ServerSync] Failed to fetch ProjectData from server")
            return false
        }
    }
}

// MARK: - Preprocessing

extension ServerSynchronize {
    
    private func preprocessExecutor(_ type: SyncType, with lastSync: Date) async {
        switch type {
        case .weekly:
            self.localAccessLogHead = localUser.accessLogHead
        case .monthly:
            await preprocessingChallenges()
            await preprocessingProject(.monthly)
        case .quarterly:
            self.localAccessLogHead = localUser.accessLogHead + 1
            await preprocessingProject(.quarterly)
        }
        print("[ServerSync] Successfully preprocessing data")
    }
    
    private func preprocessingChallenges() async {
        self.localUpdateNeedChallengeIds = self.localChallenges.map{ $0.challengeId }
    }
    
    private func preprocessingProject(_ type: SyncType) async {
        switch type {
        case .weekly:
            return
        case .monthly:
            for project in localProjects {
                if serverProjectIds.contains(project.projectId) {
                    self.localUpdateNeedProjectIds.append(project.projectId)
                    self.localUpdateNeedProjects[project.projectId] = project
                } else {
                    self.localUploadNeedProjectIds.append(project.projectId)
                    self.localUploadNeedProjects.append(project)
                }
            }
        case .quarterly:
            for project in localProjects {
                if project.extendedCount > 0 {
                    if serverProjectIds.contains(project.projectId) {
                        self.localUpdateNeedProjectIds.append(project.projectId)
                        self.localUpdateNeedProjects[project.projectId] = project
                    } else {
                        self.localUploadNeedProjectIds.append(project.projectId)
                        self.localUploadNeedProjects.append(project)
                    }
                    self.localProjectIds.append(project.projectId)
                }
            }
        }
    }
}

// MARK: - Update Server Data

extension ServerSynchronize {
    
    private func serverUpdateExecutor(_ type: SyncType, with syncDate: Date) async -> Bool {
        let batch = Firestore.firestore().batch()
        var results: [Bool] = []
        
        switch type {
        case .weekly:
            async let isServerUserUpdated = updateUserAtServer(.weekly, with: syncDate, and: batch)
            async let isServerStatUpdated = updateStatAtServer(with: syncDate, and: batch)
            async let isServerAccessLogUpdated = updateAccessLogAtServer(type: .weekly, and: batch)
            
            results = await [isServerUserUpdated, isServerStatUpdated, isServerAccessLogUpdated]
            
        case .monthly:
            async let isServerChallengeUpdated = updateChallengeStatusAtServer(batch: batch)
            async let isServerProjectUpdated = updateProjectAtServer(.monthly, with: syncDate, batch: batch)

            results = await [isServerChallengeUpdated, isServerProjectUpdated]
            
        case .quarterly:
            if await updateProjectAtServer(.quarterly, with: syncDate, batch: batch) {
                async let isServerAccessLogUpdated = updateAccessLogAtServer(type: .quarterly, and: batch)
                async let isServerUserUpdated = updateUserAtServer(.quarterly, with: syncDate, and: batch)
                async let isServerProjectLogUploaded = uploadProjectExtendAtServer(batch: batch)
                
                results = await [isServerAccessLogUpdated, isServerUserUpdated, isServerProjectLogUploaded]
            } else {
                print("[ServerSync] Failed to update server")
                return false
            }
        }
        
        do {
            if results.allSatisfy({$0}){
                try await batch.commit()
                print("[ServerSync] Successfully commit batch")
                return true
            } else {
                print("[ServerSync] Failed to commit batch")
                return false
            }
        } catch {
            print("[ServerSync] Failed to server update process")
            return false
        }
    }
    
    // User : weekly & monthly & Quarterly
    private func updateUserAtServer(_ type: SyncType, with syncDate: Date, and batch: WriteBatch) async -> Bool {
        do {
            switch type {
            case .quarterly:
                let docsRef = await userFS.getDocsRef(with: userId)
                let updatedData = try await userFS.checkUpdate(from: serverUser, to: localUser, or: localAccessLogHead, at: syncDate)
                batch.updateData(updatedData, forDocument: docsRef)
            default:
                let docsRef = await userFS.getDocsRef(with: userId)
                let updatedData = try await userFS.checkUpdate(from: serverUser, to: localUser, at: syncDate)
                batch.updateData(updatedData, forDocument: docsRef)
            }
            print("[ServerSync] Successfully set updated userData at batch")
            return true
        } catch {
            print("[ServerSync] Failed to set updated userData at batch")
            return false
        }
    }
    
    // Stat : weekly & monthly & Quarterly
    private func updateStatAtServer(with syncDate: Date, and batch: WriteBatch) async -> Bool {
        do {
            let docsRef = await statFS.getDocsRef(with: userId)
            let updateData = try await statFS.checkUpdate(from: serverStat, to: localStat, at: syncDate)
            batch.updateData(updateData, forDocument: docsRef)
            
            print("[ServerSync] Successfully set updated statData at batch")
            return true
        } catch {
            print("[ServerSync] Failed to set updated statData at batch")
            return false
        }
    }
    
    // AccessLog : weekly & monthly & Quarterly(logHeadChange)
    private func updateAccessLogAtServer(type: SyncType, and batch: WriteBatch) async -> Bool {
        switch type {
        case .quarterly:
            await accessLogFS.setDocs(with: userId, and: localAccessLogHead, and: localAccessLogs, and: batch)
            
            print("[ServerSync] Successfully set update accesslog with newLogHead at batch")
            return true
            
        default:
            let docsRef = await accessLogFS.getDocsRef(with: userId, and: localAccessLogHead)
            let updateData = await accessLogFS.checkUpdate(with: self.localAccessLogs)
            batch.updateData(updateData, forDocument: docsRef)
            
            print("[ServerSync] Successfully set update accesslog at batch")
            return true
        }
    }
    
    // Challenge : monthly
    private func updateChallengeStatusAtServer(batch: WriteBatch) async -> Bool {
        let docsRef = await challengeFS.getStatusDocsRef(with: userId, and: localUpdateNeedChallengeIds)
        for challenge in localChallenges {
            
            guard let ref = docsRef[challenge.challengeId] else {
                print("[ServerSync] Failed to set update challenge at batch")
                return false
            }
            let updatedData = challengeFS.convertObjectToStatus(with: challenge)
            batch.updateData(updatedData, forDocument: ref)
        }
        return true
    }

    
    // Project
    private func updateProjectAtServer(_ type: SyncType, with syncDate: Date, batch: WriteBatch) async -> Bool {
        switch type {
        case .weekly:
            return false
            
        case .monthly, .quarterly:
            if localUploadNeedProjects.isEmpty {
                return await updateProject(with: syncDate, batch: batch)
            } else {
                async let isUploadComplete = uploadProject(batch: batch)
                async let isUpdateComplete = updateProject(with: syncDate, batch: batch)
                
                let results = await [isUploadComplete, isUpdateComplete]
                return results.allSatisfy{ $0 }
            }
        }
    }
    
    private func uploadProject(batch: WriteBatch) async -> Bool {
        do {
            try await projectFS.setDocs(with: localUploadNeedProjects, and: userId, and: batch)
            return true
            
        } catch {
            print("[ServerSync] Failed to set upload projects at batch")
            return false
        }
    }
    
    private func updateProject(with syncDate: Date, batch: WriteBatch) async -> Bool {
        let docsRef = await projectFS.getDocsRefList(with: localUpdateNeedProjectIds, and: userId)
        
        for projectId in localUpdateNeedProjectIds {
            guard let ref = docsRef[projectId],
                  let serverData = serverProjects[projectId],
                  let localData = localUpdateNeedProjects[projectId] else {
                print("[ServerSync] Failed to set update projects at batch")
                return false
            }

            let updatedData = projectFS.checkUpdate(from: serverData, to: localData, at: syncDate)
            batch.updateData(updatedData, forDocument: ref)
        }
        return true
    }

    // Project - Quarterly
    private func uploadProjectExtendAtServer(batch: WriteBatch) async -> Bool {
        for projectLogs in localProjectLog {
            await projectExtendFS.setDocs(with: projectLogs.value, and: batch)
        }
        return true
    }
}

// MARK: - Update Local Data

extension ServerSynchronize {
    
    // executor
    private func localUpdateExecutor(_ type: SyncType, with syncDate: Date) async -> Bool {
        var results: [Bool] = []
        
        switch type {
        case .weekly:
            async let isLocalUserUpdated = updateUserAtLocal(with: syncDate, type: .weekly)
            async let isLocalStatUpdated = updateStatAtLocal(with: syncDate)
            
            results = await [isLocalUserUpdated, isLocalStatUpdated]
            print("[ServerSync] Successfully proceed weekly update")
            
        case .monthly:
            results.append(await updateProjectAtLocal(with: syncDate))
            print("[ServerSync] Successfully proceed monthly update")
            
        case .quarterly:
            async let isLocalUserUpdated = updateUserAtLocal(with: syncDate, type: .quarterly)
            async let isLocalAccessLogCleanUp = cleanupAccessLogAtLocal()
            async let isLocalProjectLogCleanUp = cleanupProjectLogAtLocal()
            
            results = await [isLocalUserUpdated, isLocalAccessLogCleanUp, isLocalProjectLogCleanUp]
            print("[ServerSync] Successfully proceed quarterly update")
        }

        if results.allSatisfy({ $0 }) {
            if await LocalStorageManager.shared.saveContext() {
                print("[ServerSync] Successfully apply updatedData at local")
                return true
            } else {
                print("[ServerSync] Failed to apply updatedData at local")
                return false
            }
        } else {
            print("[ServerSync] Failed to local update process")
            return false
        }
    }
    
    // User
    private func updateUserAtLocal(with syncDate: Date, type: UpdateType) async -> Bool {
        do {
            switch type {
            case .quarterly:
                let updated = UserUpdateDTO(userId: userId, newLogHead: localAccessLogHead ,newSyncedAt: syncDate)
                return try userCD.updateObject(with: updated)
            default:
                let updated = UserUpdateDTO(userId: userId, newSyncedAt: syncDate)
                return try userCD.updateObject(with: updated)
            }
        } catch {
            print("[ServerSync] Failed to update user data at local")
            return false
        }
    }
    
    // Stat
    private func updateStatAtLocal(with syncDate: Date) async -> Bool {
        do {
            let updated = StatUpdateDTO(userId: userId, newSyncedAt: syncDate)
            return try statCD.updateObject(with: updated)
        } catch {
            print("[ServerSync] Failed to update stat data at local")
            return false
        }
    }
    
    // AccessLog
    private func cleanupAccessLogAtLocal() async -> Bool {
        do {
            try accessLogCD.deleteObject(with: userId)
            return true
        } catch {
            print("[ServerSync] Failed to update accessLog at local")
            return false
        }
    }
    
    // Project
    private func updateProjectAtLocal(with syncDate: Date) async -> Bool {
        async let isProjectSyncedAtUpdated = updateProjectSyncedAt(with: syncDate)
        async let isTruncatedProjectDeleted = cleanupProjectAtLocal()
        
        let results = await [isProjectSyncedAtUpdated, isTruncatedProjectDeleted]
        return results.allSatisfy{ $0 }
    }
    
    private func updateProjectSyncedAt(with syncDate: Date) async -> Bool {
        do {
            var results: [Bool] = []
            for project in localProjects {
                let updated = ProjectUpdateDTO(projectId: project.projectId, userId: userId, newSyncedAt: syncDate)
                results.append(try projectCD.updateObject(with: updated))
            }
            return results.allSatisfy{ $0 }
        } catch {
            print("[ServerSync] Failed to update project at local")
            return false
        }
    }
    
    private func cleanupProjectAtLocal() async -> Bool {
        do {
            return try projectCD.deleteTruncateObject(with: userId)
        } catch {
            print("[ServerSync] Failed to truncate project at local")
            return false
        }
    }
    
    // ProjectLog
    private func cleanupProjectLogAtLocal() async -> Bool {
        do {
            for localProjectLogId in self.localProjectIds {
                try await projectExtendCD.deleteObject(with: localProjectLogId, and: userId)
            }
            return true
        } catch {
            print("[ServerSync] Failed to truncate projectLog at local")
            return false
        }
    }
}


// MARK: - Fetch Mock Data
extension ServerSynchronize{
    

}
