//
//  SyncServerWithLocal.swift
//  teamplan
//
//  Created by 크로스벨 on 1/10/24.
//  Copyright © 2024 team1os. All rights reserved.
//

import CoreData
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
    private let storageManager: LocalStorageManager
    
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
    
    // Local Properties
    private var userId: String
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
        
        self.storageManager = LocalStorageManager.shared
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
            // fetch data
            async let isLocalDataFetched = localFetchExecutor(.weekly, with: syncDate)
            async let isServerDataFetched = serverFetchExecutor(.weekly)
            
            results = await [isLocalDataFetched, isServerDataFetched]
            
            if results.allSatisfy({$0}) {
                
                // 
                await preprocessExecutor(.weekly, with: syncDate)
                let isServerUpdated = await serverUpdateExecutor(.weekly, with: syncDate)

                if isServerUpdated {
                    return localUpdateExecutor(.weekly, with: syncDate)
                } else {
                    return false
                }
            } else {
                return false
            }
            
        case .monthly:
            // fetch data
            async let isLocalDataFetched = localFetchExecutor(.monthly, with: syncDate)
            async let isServerDataFetched = serverFetchExecutor(.monthly)
            
            results = await [isLocalDataFetched, isServerDataFetched]
            
            if results.allSatisfy({$0}) {
                await preprocessExecutor(.monthly, with: syncDate)
                let isServerUpdated = await serverUpdateExecutor(.monthly, with: syncDate)
                
                if isServerUpdated {
                    return localUpdateExecutor(.monthly, with: syncDate)
                } else {
                    return false
                }
            } else {
                return false
            }
            
        case .quarterly:
            // fetch data
            async let isLocalDataFetched = localFetchExecutor(.quarterly, with: syncDate)
            async let isServerDataFetched = serverFetchExecutor(.quarterly)
            
            results = await [isLocalDataFetched, isServerDataFetched]
            
            if results.allSatisfy({$0}) {
                await preprocessExecutor(.quarterly, with: syncDate)
                let isServerUpdated = await serverUpdateExecutor(.quarterly, with: syncDate)
                
                if isServerUpdated {
                    return localUpdateExecutor(.quarterly, with: syncDate)
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
        let context = storageManager.context
        
        return context.performAndWait {
            switch type {
            case .weekly:
                results = [
                    fetchUserFromLocal(context: context),
                    fetchStatFromLocal(context: context),
                    fetchAccessLogFromLocal(context: context)
                ]
                
            case .monthly:
                results = [
                    fetchChallengeFromLocal(context: context, with: syncDate),
                    fetchProjectFromLocal(context: context)
                ]
                
            case .quarterly:
                results = [
                    fetchUserFromLocal(context: context),
                    fetchAccessLogFromLocal(context: context),
                    fetchProjectLogFromLocal(context: context)
                ]
            }
            if results.allSatisfy({$0}){
                print("[ServerSync] Successfully fetch local data")
                return true
            } else {
                print("[ServerSync] Failed to fetch local data")
                return false
            }
        }
    }
    
    // User
    private func fetchUserFromLocal(context: NSManagedObjectContext) -> Bool {
        do {
            guard try userCD.getObject(context: context, userId: userId) else {
                print("[ServerSync] Failed to convert UserData")
                return false
            }
            self.localUser = userCD.object
            return true
        } catch {
            print("[ServerSync] Failed to fetch UserData from storage")
            return false
        }
    }
    
    // Stat
    private func fetchStatFromLocal(context: NSManagedObjectContext) -> Bool {
        do {
            guard try statCD.getObject(context: context, userId: userId) else {
                print("[ServerSync] Failed to convert StatData")
                return false
            }
            self.localStat = statCD.object
            return true
        } catch {
            print("[ServerSync] Failed to fetch StatData from storage")
            return false
        }
    }
    
    // AccessLog
    private func fetchAccessLogFromLocal(context: NSManagedObjectContext) -> Bool {
        do {
            guard try accessLogCD.getFullObjects(context: context, userId: userId) else {
                print("[ServerSync] Failed to convert AccessLog")
                return false
            }
            self.localAccessLogs = accessLogCD.objects
            return true
        } catch {
            print("[ServerSync] Failed to fetch AccessLog from storage")
            return false
        }
    }
    
    // Challenge
    private func fetchChallengeFromLocal(context: NSManagedObjectContext, with syncDate: Date) -> Bool {
        do {
            guard try challengeCD.getChangedObjects(context: context, userId: userId, syncDate: syncDate) else {
                print("[ServerSync] Failed to convert Challenge")
                return false
            }
            self.localChallenges = challengeCD.objects
            return true
        } catch {
            print("[ServerSync] Failed to fetch Challenges from storage")
            return false
        }
    }
    
    // Project
    private func fetchProjectFromLocal(context: NSManagedObjectContext) -> Bool {
        do {
            guard try projectCD.getValidObjects(context: context, with: userId) else {
                print("[ServerSync] Failed to convert Project")
                return false
            }
            self.localProjects = projectCD.objectList
            return true
        } catch {
            print("[ServerSync] Failed to fetch ProjectInfo from storage")
            return false
        }
    }
    
    // ProjectLog
    private func fetchProjectLogFromLocal(context: NSManagedObjectContext) -> Bool {
        for projectLogId in localProjectIds {
            guard projectExtendCD.getObjects(context: context, with: projectLogId, and: userId) else {
                print("[ServerSync] Failed to convert ExtendLog")
                return false
            }
            print("[ServerSync] ProjectLog that need to upload : \(projectExtendCD.objects.count)")
            self.localProjectLog[projectLogId] = projectExtendCD.objects
        }
        return true
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
        var tasks: [ () async -> Bool ] = []
        var results: [Bool] = []
        
        switch type {
        case .weekly:
            tasks = [
                { await self.updateUserAtServer(.weekly, with: syncDate, and: batch) },
                { await self.updateStatAtServer(with: syncDate, and: batch) },
                { await self.updateAccessLogAtServer(type: .weekly, and: batch) }
            ]
            
        case .monthly:
            tasks = [
                { await self.updateChallengeStatusAtServer(batch: batch) },
                { await self.updateProjectAtServer(.monthly, with: syncDate, batch: batch) }
            ]
            
        case .quarterly:
            tasks = [
                { await self.updateProjectAtServer(.quarterly, with: syncDate, batch: batch) },
                { await self.updateAccessLogAtServer(type: .quarterly, and: batch) },
                { await self.updateUserAtServer(.quarterly, with: syncDate, and: batch) },
                { await self.uploadProjectExtendAtServer(batch: batch) }
            ]
        }
        for task in tasks {
            if await !task() {
                print("[ServerSync] Failed to add update data at batch")
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
    private func localUpdateExecutor(_ type: SyncType, with syncDate: Date) -> Bool {
        let context = storageManager.context
        var results: [Bool] = []
        
        return context.performAndWait {
            switch type {
            case .weekly:
                results = [
                    updateUserAtLocal(context: context, with: syncDate, type: .weekly),
                    updateStatAtLocal(context: context, with: syncDate)
                ]
            case .monthly:
                results = [
                    updateProjectSyncedAt(context: context, with: syncDate),
                    cleanupProjectAtLocal(context: context)
                ]
            case .quarterly:
                results = [
                    updateUserAtLocal(context: context, with: syncDate, type: .quarterly),
                    cleanupAccessLogAtLocal(context: context),
                    cleanupProjectLogAtLocal(context: context)
                ]
            }
            if results.allSatisfy({ $0 }) {
                if storageManager.saveContext() {
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
    }
    
    // User
    private func updateUserAtLocal(context: NSManagedObjectContext, with syncDate: Date, type: UpdateType) -> Bool {
        do {
            switch type {
            case .quarterly:
                let updated = UserUpdateDTO(userId: userId, newLogHead: localAccessLogHead ,newSyncedAt: syncDate)
                return try userCD.updateObject(context: context, dto: updated)
            default:
                let updated = UserUpdateDTO(userId: userId, newSyncedAt: syncDate)
                return try userCD.updateObject(context: context, dto: updated)
            }
        } catch {
            print("[ServerSync] Failed to update user data at local")
            return false
        }
    }
    
    // Stat
    private func updateStatAtLocal(context: NSManagedObjectContext, with syncDate: Date) -> Bool {
        do {
            let updated = StatUpdateDTO(userId: userId, newSyncedAt: syncDate)
            return try statCD.updateObject(context: context, dto: updated)
        } catch {
            print("[ServerSync] Failed to update stat data at local")
            return false
        }
    }
    
    // AccessLog
    private func cleanupAccessLogAtLocal(context: NSManagedObjectContext) -> Bool {
        do {
            try accessLogCD.deleteObject(context: context, userId: userId)
            return true
        } catch {
            print("[ServerSync] Failed to update accessLog at local")
            return false
        }
    }
    
    // Project
    private func updateProjectSyncedAt(context: NSManagedObjectContext, with syncDate: Date) -> Bool {
        do {
            var results: [Bool] = []
            for project in localProjects {
                let updated = ProjectUpdateDTO(projectId: project.projectId, userId: userId, newSyncedAt: syncDate)
                results.append(try projectCD.updateObject(context: context, with: updated))
            }
            return results.allSatisfy{ $0 }
        } catch {
            print("[ServerSync] Failed to update project at local")
            return false
        }
    }
    
    private func cleanupProjectAtLocal(context: NSManagedObjectContext) -> Bool {
        do {
            return try projectCD.deleteTruncateObject(context: context, with: userId)
        } catch {
            print("[ServerSync] Failed to truncate project at local")
            return false
        }
    }
    
    // ProjectLog
    private func cleanupProjectLogAtLocal(context: NSManagedObjectContext) -> Bool {
        do {
            for localProjectLogId in self.localProjectIds {
                try projectExtendCD.deleteObject(context: context, with: localProjectLogId, and: userId)
            }
            return true
        } catch {
            print("[ServerSync] Failed to truncate projectLog at local")
            return false
        }
    }
}
