//
//  SynchronizeLocal.swift
//  teamplan
//
//  Created by 크로스벨 on 1/10/24.
//  Copyright © 2024 team1os. All rights reserved.
//

import Foundation

final class SynchronizeLocal{
    
    //================================
    // MARK: - Parameter
    //================================
    let userFS = UserServicesFirestore()
    let userCD = UserServicesCoredata()
    let statFS = StatisticsServicesFirestore()
    let statCD = StatisticsServicesCoredata()
    let challengeCD = ChallengeServicesCoredata()
    let challengeManager = ChallengeManager()
    
    var logManager = LogManager()
    var userId: String
    
    private var rollbackStack: [() throws -> Void ] = []
    
    //===============================
    // MARK: - Initialize
    //===============================
    init(){
        self.userId = "unknown"
    }
    
    func readySync(with userId: String, and manager: LogManager) throws {
        self.userId = userId
        self.logManager = manager
    }
}

//===============================
// MARK: - Main Function
//===============================
extension SynchronizeLocal{
    
    func syncExecutor(with syncDate: Date) async throws {
        do {
            // Erase Every Local Data
            try clearLocal()
            
            // User
            let user = try await getUserFromServer()
            try resetLocalUser(with: user, and: syncDate)
            rollbackStack.append(rollbackResetUser)
            
            // Statistics
            let stat = try await getStatFromServer()
            try resetLocalStat(with: stat)
            rollbackStack.append(rollbackResetStat)
            
            // Access Log
            let accessLogList = try await getAccessLogFromServer()
            try resetLocalAccessLog(with: accessLogList)
            rollbackStack.append(rollbackResetAccessLog)
            
            // Challenge Log
            let challengeLogList = try await getChallengeLogFromServer()
            try resetLocalChallengeLog(with: challengeLogList)
            rollbackStack.append(rollbackResetChallengeLog)
            
            // Challenge
            let challengeList = try await getChallengeListFromServer()
            try resetLocalChallenge(stat: stat, logList: challengeLogList, challengeList: challengeList)
            rollbackStack.append(rollbackResetChallenge)

            rollbackStack.removeAll()
            
        } catch {
            try rollbackAll()
            print("(Service) There was an unexpected error while Sync Server To Local UserData at 'LoginLoading' : \(error)")
            throw error
        }
    }
    
    private func rollbackAll() throws {
        do {
            for rollback in rollbackStack.reversed() {
                try rollback()
            }
            rollbackStack.removeAll()
        } catch {
            throw error
        }
    }
    
    private func clearLocal() throws {
        try userCD.deleteUser(with: userId)
        try statCD.deleteStatistics(with: userId)
        try logManager.deleteAllAccessLogAtLocal()
        try logManager.deleteAllChallengeLogAtLocal()
        try challengeManager.delChallenge(with: userId)
    }
}

//===============================
// MARK: - SP1: Fetch Server Data
//===============================
extension SynchronizeLocal{
    
    // User
    private func getUserFromServer() async throws -> UserObject {
        return try await userFS.getUser(from: userId)
    }
    
    // Statistics
    private func getStatFromServer() async throws -> StatisticsObject {
        return try await statFS.getStatistics(from: userId)
    }
    
    // Access Log
    private func getAccessLogFromServer() async throws -> [AccessLog] {
        return try await logManager.getAccessLogListAtServer()
    }
    
    // Challenge Log
    private func getChallengeLogFromServer() async throws -> [ChallengeLog] {
        return try await logManager.getChallengeLogListAtServer()
    }
    
    // Challenge
    private func getChallengeListFromServer() async throws -> [ChallengeObject] {
        try await challengeManager.getChallengesFromServer()
        challengeManager.configChallenge(with: userId)
        return try challengeManager.getChallenges()
    }
}

//===============================
// MARK: - SP2: Apply Server To Local
//===============================
extension SynchronizeLocal{
    
    // User
    private func resetLocalUser(with object: UserObject, and loginDate: Date) throws {
        try userCD.setUser(with: object, and: loginDate)
    }
    
    private func rollbackResetUser() throws {
        try userCD.deleteUser(with: userId)
    }
    
    // Statistics
    private func resetLocalStat(with object: StatisticsObject) throws {
        try statCD.setStatistics(with: object)
    }
    
    private func rollbackResetStat() throws {
        try statCD.deleteStatistics(with: userId)
    }
    
    // Access Log
    private func resetLocalAccessLog(with logList: [AccessLog]) throws {
        try logManager.setAccessLogAtLocal(with: logList)
    }
    
    private func rollbackResetAccessLog() throws {
        try logManager.deleteAllAccessLogAtLocal()
    }
    
    // Challenge Log
    private func resetLocalChallengeLog(with logList: [ChallengeLog]) throws {
        try logManager.setChallengeLogAtLocal(with: logList)
    }
    
    private func rollbackResetChallengeLog() throws {
        try logManager.deleteAllChallengeLogAtLocal()
    }
    
    // Challenge
    private func resetLocalChallenge(stat: StatisticsObject, logList: [ChallengeLog], challengeList: [ChallengeObject]) throws {
        for log in logList {
            try restoreChallengeProgress(stat: stat, challengeLog: log.log_complete, challengeList: challengeList)
        }
    }
    
    private func rollbackResetChallenge() throws {
        try challengeManager.delChallenge(with: userId)
    }
}

//===============================
// MARK: - Support Function
//===============================
extension SynchronizeLocal{
    
    private func restoreChallengeProgress(stat: StatisticsObject, challengeLog: [Int:Date], challengeList: [ChallengeObject]) throws {
        for (key, date) in challengeLog {
            guard let challenge = challengeList.first(where: { $0.chlg_id == key }) else {
                throw SyncLocalError.UnexpectedChallengeProgressRestoreError
            }
            try updateChallenge(object: challenge, finishDate: date)
        }
    }
    
    private func updateChallenge(object: ChallengeObject, finishDate: Date) throws {
        let updated = ChallengeUpdateDTO(challengeId: object.chlg_id, userId: userId,
                                         newSelected: false, newStatus: true, newLock: false,
                                         newFinishedAt: finishDate
        )
        try challengeCD.updateChallenge(with: updated)
    }
}

//================================
// MARK: - Exception
//================================
enum SyncLocalError: LocalizedError {
    case UnexpectedChallengeProgressRestoreError
    
    var errorDescription: String? {
        switch self {
        case .UnexpectedChallengeProgressRestoreError:
            return "Sync: There was an unexpected error while Restore Challenge Progress"
        }
    }
}
