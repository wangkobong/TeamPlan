//
//  SynchronizeLocal.swift
//  teamplan
//
//  Created by 크로스벨 on 1/10/24.
//  Copyright © 2024 team1os. All rights reserved.
//

import Foundation

final class SyncLocalWithServer{
    
    private let userCD = UserServicesCoredata()
    private let statCD = StatisticsServicesCoredata()
    private let coreValueCD = CoreValueServicesCoredata()
    private let challengeCD = ChallengeServicesCoredata()
    private let accessLogCD = AccessLogServicesCoredata()
    private let projectCD = ProjectServicesCoredata()
    
    private let userFS = UserServicesFirestore()
    private let statFS = StatisticsServicesFirestore()
    private let coreValueFS = CoreValueServicesFirestore()
    private let challengeFS = ChallengeServicesFirestore()
    private let accessLogFS = AccessLogServicesFirestore()
    private let projectFS = ProjectServicesFirestore()
    
    private var userId: String
    private var rollbackStack: [() throws -> Void ] = []
    private var challengeIdSet = Set<Int>()
    
    init(with userId: String) {
        self.userId = userId
    }
}


// MARK: - Main
extension SyncLocalWithServer{
    
    func syncExecutor(with userId: String) async throws {
        self.userId = userId
        do {
            let user = try await getUserFromServer()
            try resetLocalUser(with: user)
            rollbackStack.append(rollbackResetUser)
            
            try resetLocalStat(with: try await getStatFromServer())
            rollbackStack.append(rollbackResetStat)
            
            try resetLocalCoreValue(with: try await getCoreValueFromServer())
            rollbackStack.append(rollbackResetCoreValue)
            
            try resetLocalAccessLog(with: try await getAccessLogFromServer(with: user.accessLogHead))
            rollbackStack.append(rollbackResetAccessLog)
            
            try resetLocalProject(with: try await getProjectFromServer())
            rollbackStack.append(rollbackResetProject)
        
            try await resetLocalChallenge(with: try await getChallengeFromServer())
            rollbackStack.append(rollbackResetChallenge)
            
            rollbackStack.removeAll()
            
        } catch {
            try rollbackAll()
            throw error
        }
    }
    
    private func rollbackAll() throws {
        for rollback in rollbackStack.reversed() {
            try rollback()
        }
        rollbackStack.removeAll()
    }
}

// MARK: - Apply Local
extension SyncLocalWithServer{
    
    // User
    private func resetLocalUser(with object: UserObject) throws {
        try userCD.setObject(with: object)
    }
    private func rollbackResetUser() throws {
        try userCD.deleteObject(with: userId)
    }
    
    // Stat
    private func resetLocalStat(with object: StatisticsObject) throws {
        try statCD.setObject(with: object)
    }
    private func rollbackResetStat() throws {
        try statCD.deleteObject(with: userId)
    }
    
    // CoreValue
    private func resetLocalCoreValue(with object: CoreValueObject) throws {
        try coreValueCD.setObject(with: object)
    }
    private func rollbackResetCoreValue() throws {
        try coreValueCD.deleteObject(with: userId)
    }
    
    // AccessLog
    private func resetLocalAccessLog(with logList: [AccessLog]) throws {
        for log in logList {
            try accessLogCD.setObject(with: log)
        }
    }
    private func rollbackResetAccessLog() throws {
        try accessLogCD.deleteObject(with: userId)
    }
    
    // Project
    private func resetLocalProject(with list: [ProjectObject]) throws {
        for project in list {
            try projectCD.setObject(with: project)
        }
    }
    private func rollbackResetProject() throws {
        try projectCD.deleteAllObject(with: userId)
    }
    
    // Challenge
    private func resetLocalChallenge(with challengeList: [ChallengeObject]) async throws {
        for challenge in challengeList {
            try await challengeCD.setObject(with: challenge)
        }
    }
    private func rollbackResetChallenge() throws {
        try challengeCD.deleteObject(with: userId)
    }
}


// MARK: - Fetch From Server
extension SyncLocalWithServer{
    
    // User
    private func getUserFromServer() async throws -> UserObject {
        return try await userFS.getDocs(with: userId)
    }
    
    // Stat
    private func getStatFromServer() async throws -> StatisticsObject {
        return try await statFS.getDocs(with: userId)
    }
    
    // CoreValue
    private func getCoreValueFromServer() async throws -> CoreValueObject {
        return try await coreValueFS.getDocs(with: userId)
    }
    
    // AccessLog
    private func getAccessLogFromServer(with logHead: Int) async throws -> [AccessLog] {
        return try await accessLogFS.getDocs(with: userId, and: logHead)
    }
    
    // Project
    private func getProjectFromServer() async throws -> [ProjectObject] {
        return try await projectFS.getDocsList(with: userId)
    }
    
    // Challenge
    private func getChallengeFromServer() async throws -> [ChallengeObject] {
        do {
            let infoList = try await getChallengeInfoDocs()
            let statusList = try await getChallengeStatusDocs()
            let challengeList = try convertToObject(infoList, statusList)
            
            return challengeList
        } catch {
            print("[Sync] Struct Challenge Object Failed at Synchronize: \(error)")
            throw error
        }
    }
    
    private func getChallengeInfoDocs() async throws -> [ChallengeInfoDTO] {
        let rawInfoList = try await challengeFS.getInfoDocsList()
        var refineInfoList: [ChallengeInfoDTO] = []
        
        for challenge in rawInfoList where !challengeIdSet.contains(challenge.challengeId) {
            challengeIdSet.insert(challenge.challengeId)
            refineInfoList.append(challenge)
        }
        
        return refineInfoList
    }
    
    private func getChallengeStatusDocs() async throws -> [ChallengeStatusDTO] {
        let rawStatusList = try await challengeFS.getStatusDocsList(with: userId)
        var refineStatusList: [ChallengeStatusDTO] = []
        
        for challenge in rawStatusList where challengeIdSet.contains(challenge.challengeId) {
            refineStatusList.append(challenge)
        }
        
        return refineStatusList
    }
    
    private func convertToObject(_ infoList: [ChallengeInfoDTO], _ statusList: [ChallengeStatusDTO]) throws -> [ChallengeObject] {
        var challengeObject: ChallengeObject
        var challengeList: [ChallengeObject] = []
        
        for challengeId in challengeIdSet {
            guard let info = infoList.first(where: { $0.challengeId == challengeId }) else {
                throw ChallengeError.UnexpectedChallengeArrayError
            }
            guard let status = statusList.first(where: { $0.challengeId == challengeId }) else {
                throw ChallengeError.UnexpectedChallengeArrayError
            }
            challengeObject = prepareChallenge(with: info, and: status)
            challengeList.append(challengeObject)
        }
        return challengeList
    }
    
    private func prepareChallenge(with info: ChallengeInfoDTO, and status: ChallengeStatusDTO) -> ChallengeObject {
        return ChallengeObject(
            challengeId: status.challengeId,
            userId: status.userId,
            title: info.title,
            desc: info.desc,
            goal: info.goal,
            type: info.type,
            reward: info.reward,
            step: info.step,
            version: info.version,
            status: status.status,
            lock: status.lock,
            progress: status.progress,
            selectStatus: status.selectStatus,
            selectedAt: status.selectedAt,
            unselectedAt: status.unselectedAt,
            finishedAt: status.finishedAt
        )
    }
}


