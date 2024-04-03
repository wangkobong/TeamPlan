//
//  SynchronizeLocal.swift
//  teamplan
//
//  Created by 크로스벨 on 1/10/24.
//  Copyright © 2024 team1os. All rights reserved.
//

import Foundation

final class SyncLocalWithServer{
    
    private let userCD: UserServicesCoredata
    private let statCD: StatisticsServicesCoredata
    private let coreValueCD: CoreValueServicesCoredata
    private let challengeCD: ChallengeServicesCoredata
    private let accessLogCD: AccessLogServicesCoredata
    private let projectCD: ProjectServicesCoredata
    
    private let userFS = UserServicesFirestore()
    private let statFS = StatisticsServicesFirestore()
    private let coreValueFS = CoreValueServicesFirestore()
    private let challengeFS = ChallengeServicesFirestore()
    private let accessLogFS = AccessLogServicesFirestore()
    private let projectFS = ProjectServicesFirestore()
    
    private var userId: String
    private var rollbackStack: [() throws -> Void ] = []
    
    init(with userId: String, controller: CoredataController = CoredataController()) {
        self.userId = userId
        self.userCD = UserServicesCoredata(coredataController: controller)
        self.statCD = StatisticsServicesCoredata(coredataController: controller)
        self.coreValueCD = CoreValueServicesCoredata(coredataController: controller)
        self.challengeCD = ChallengeServicesCoredata(coredataController: controller)
        self.accessLogCD = AccessLogServicesCoredata(coredataController: controller)
        self.projectCD = ProjectServicesCoredata(coredataController: controller)
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
            
            let stat = try await getStatFromServer()
            try resetLocalStat(with: stat)
            rollbackStack.append(rollbackResetStat)
            
            let coreValue = try await getCoreValueFromServer()
            try resetLocalCoreValue(with: coreValue)
            rollbackStack.append(rollbackResetCoreValue)
            
            let accessLogList = try await getAccessLogFromServer(with: user.accessLogHead)
            try resetLocalAccessLog(with: accessLogList)
            rollbackStack.append(rollbackResetAccessLog)
            
            let projectList = try await getProjectFromServer()
            try resetLocalProject(with: projectList)
            rollbackStack.append(rollbackResetProject)
            
            let challengeList = try await getChallengeFromServer()
            try resetLocalChallenge(with: challengeList)
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
    private func resetLocalChallenge(with challengeList: [ChallengeObject]) throws {
        for challenge in challengeList {
            try challengeCD.setObject(with: challenge)
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
        async let getInfoList = try await challengeFS.getInfoDocsList()
        async let getStatusList = try await challengeFS.getStatusDocsList(with: userId)
        let (infoList, statusList) = try await (getInfoList, getStatusList)
    
        let (infoDict, statusDict) = convertToDictionary(infoList, statusList)
        let challengeList = try createChallengeObjects(infoDict, statusDict)
        return challengeList
    }
    
    private func convertToDictionary(_ infoList: [ChallengeInfoDTO], _ statusList: [ChallengeStatusDTO]) -> (infoDict: [Int: ChallengeInfoDTO], statusDict: [Int: ChallengeStatusDTO]) {
        let infoDict = Dictionary(uniqueKeysWithValues: infoList.map { ($0.challengeId, $0) })
        let statusDict = Dictionary(uniqueKeysWithValues: statusList.map { ($0.challengeId, $0) })
        return (infoDict, statusDict)
    }

    private func createChallengeObjects(_ infoDict: [Int: ChallengeInfoDTO], _ statusDict: [Int: ChallengeStatusDTO]) throws -> [ChallengeObject] {
        var challengeList = [ChallengeObject]()
        for (challengeId, info) in infoDict {
            guard let status = statusDict[challengeId] else {
                throw FirestoreError.convertFailure(serviceName: .challenge) // 대응되는 status 정보가 없는 경우 예외 처리
            }
            let challengeObject = prepareChallenge(with: info, and: status)
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


