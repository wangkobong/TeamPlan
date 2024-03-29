//
//  SynchronizeLocal.swift
//  teamplan
//
//  Created by 크로스벨 on 1/10/24.
//  Copyright © 2024 team1os. All rights reserved.
//

import Foundation

final class SyncLocalWithServer{
    
    //================================
    // MARK: - Properties
    //================================
    // for service
    private let util = Utilities()
    private let controller = CoredataController()
    
    private let userCD: UserServicesCoredata
    private let statCD: StatisticsServicesCoredata
    private let challengeCD: ChallengeServicesCoredata
    private let accessLogCD: AccessLogServicesCoredata
    
    private let userFS = UserServicesFirestore()
    private let statFS = StatisticsServicesFirestore()
    private let challengeFS = ChallengeServicesFirestore()
    private let accessLogFS = AccessLogServicesFirestore()

    private var userId: String
    private var challengeStep: [Int:Int] =  [
        ChallengeType.serviceTerm.rawValue : 1,
        ChallengeType.totalTodo.rawValue : 1,
        ChallengeType.projectAlert.rawValue : 1,
        ChallengeType.projectFinish.rawValue : 1,
        ChallengeType.waterDrop.rawValue : 1
    ]
    private var rollbackStack: [() throws -> Void ] = []
    
    init(with userId: String) {
        self.userId = userId
        self.userCD = UserServicesCoredata(coredataController: controller)
        self.statCD = StatisticsServicesCoredata(coredataController: controller)
        self.challengeCD = ChallengeServicesCoredata(coredataController: controller)
        self.accessLogCD = AccessLogServicesCoredata(coredataController: controller)
    }
}

//===============================
// MARK: - Main Function
//===============================
extension SyncLocalWithServer{
    
    func syncExecutor(with userId: String) async throws {
        self.userId = userId
        do {
            let user = try await getUserFromServer()
            try resetLocalUser(with: user)
            rollbackStack.append(rollbackResetUser)
            print("successfully get user data from server")
            
            let stat = try await getStatFromServer()
            try resetLocalStat(with: stat)
            rollbackStack.append(rollbackResetStat)
            print("successfully get stat data from server")
            
            let accessLogList = try await getAccessLogFromServer(with: user.accessLogHead)
            try resetLocalAccessLog(with: accessLogList)
            rollbackStack.append(rollbackResetAccessLog)
            print("successfully get log data from server")
            
            let challengeList = try await getChallengeFromServer()
            try resetLocalChallenge(with: challengeList)
            rollbackStack.append(rollbackResetChallenge)
            print("successfully get status data from server")
            
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

// MARK: - Fetch Server Data
extension SyncLocalWithServer{
    
    private func getUserFromServer() async throws -> UserObject {
        return try await userFS.getDocs(with: userId)
    }
    
    private func getStatFromServer() async throws -> StatisticsObject {
        return try await statFS.getDocs(with: userId)
    }
    
    private func getAccessLogFromServer(with logHead: Int) async throws -> [AccessLog] {
        return try await accessLogFS.getDocs(with: userId, and: logHead)
    }
    
    private func getChallengeFromServer() async throws -> [ChallengeObject] {
        async let getInfoList = try await challengeFS.getInfoDocsList()
        async let getStatusList = try await challengeFS.getStatusDocsList(with: userId)
        
        let (infoList, statusList) = try await (getInfoList, getStatusList)
        
        let challengeList = try infoList.compactMap { info -> ChallengeObject? in
            guard let status = statusList.first(where: { $0.challengeId == info.challengeId }) else {
                throw FirestoreError.convertFailure(serviceName: .challenge)
            }
            return prepareChallenge(with: info, and: status)
        }
        if challengeList.count != infoList.count {
            throw FirestoreError.convertFailure(serviceName: .challenge)
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


// MARK: - Apply Local
extension SyncLocalWithServer{
    
    // User
    private func resetLocalUser(with object: UserObject) throws {
        try userCD.setObject(with: object)
    }
    private func rollbackResetUser() throws {
        try userCD.deleteObject(with: userId)
    }
    
    // Statistics
    private func resetLocalStat(with object: StatisticsObject) throws {
        try statCD.setObject(with: object)
    }
    private func rollbackResetStat() throws {
        try statCD.deleteObject(with: userId)
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
