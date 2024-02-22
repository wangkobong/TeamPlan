//
//  SynchronizeLocal.swift
//  teamplan
//
//  Created by 크로스벨 on 1/10/24.
//  Copyright © 2024 team1os. All rights reserved.
//

import Foundation

final class SyncLocaltoServer{
    
    //================================
    // MARK: - Properties
    //================================
    // for service
    private let util = Utilities()
    private let userFS = UserServicesFirestore()
    private let userCD = UserServicesCoredata()
    private let statFS = StatisticsServicesFirestore()
    private let statCD = StatisticsServicesCoredata()
    private let challengeCD = ChallengeServicesCoredata()
    private let challengeManager = ChallengeManager()
    private var logManager = LogManager()
    private var userId: String = "unknown"
    private var challengeStep: [Int:Int] =  [
        ChallengeType.serviceTerm.rawValue : 1,
        ChallengeType.totalTodo.rawValue : 1,
        ChallengeType.projectAlert.rawValue : 1,
        ChallengeType.projectFinish.rawValue : 1,
        ChallengeType.waterDrop.rawValue : 1
    ]
    private var rollbackStack: [() throws -> Void ] = []
    
    // for log
    private let location = "SyncLocaltoServer"
}

//===============================
// MARK: - Main Function
//===============================
extension SyncLocaltoServer{
    
    func syncExecutor(with syncDate: Date, by userId: String) async throws {
        do {
            self.userId = userId
            util.log(LogLevel.info, location, "Start Local Synchronize Process", userId)
            
            // User
            let user = try await getUserFromServer()
            try resetLocalUser(with: user, and: syncDate)
            rollbackStack.append(rollbackResetUser)
            util.log(LogLevel.info, location, "UserData Synchronize Complete", userId)
            
            // Statistics
            let stat = try await getStatFromServer()
            try resetLocalStat(with: stat)
            rollbackStack.append(rollbackResetStat)
            util.log(LogLevel.info, location, "Statistics Synchronize Complete", userId)
            
            // Init Log Manager
            self.logManager.readyParameter(userId: userId, caller: location)
            try self.logManager.readyManager()
            util.log(LogLevel.info, location, "LogManager Initialize Complete", userId)
            
            // Access Log
            let accessLogList = try await getAccessLogFromServer()
            try resetLocalAccessLog(with: accessLogList)
            rollbackStack.append(rollbackResetAccessLog)
            util.log(LogLevel.info, location, "AccessLog Synchronize Complete", userId)
            
            // Challenge Log
            let challengeLogList = try await getChallengeLogFromServer()
            try resetLocalChallengeLog(with: challengeLogList)
            rollbackStack.append(rollbackResetChallengeLog)
            util.log(LogLevel.info, location, "ChallengeLog Synchronize Complete", userId)
            
            // Challenge
            let challengeList = try await getChallengeListFromServer()
            try resetLocalChallenge(stat: stat, logList: challengeLogList, challengeList: challengeList)
            rollbackStack.append(rollbackResetChallenge)
            util.log(LogLevel.info, location, "Challenge Synchronize Complete", userId)
            
            rollbackStack.removeAll()
            
        } catch {
            util.log(LogLevel.critical, location,
                     "There was an unexpected error while Sync Server To Local Data: \(error)", userId)
            try rollbackAll()
            throw error
        }
    }
    
    private func rollbackAll() throws {
        do {
            for rollback in rollbackStack.reversed() {
                try rollback()
            }
            util.log(LogLevel.info, location, "Rollback Process Complete", userId)
            rollbackStack.removeAll()
        } catch {
            util.log(LogLevel.critical, location, "Unexpected Error While Processing Rollback: \(error)", userId)
            throw error
        }
    }
    // Test Function
    private func clearLocalData() throws {
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
extension SyncLocaltoServer{
    
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
extension SyncLocaltoServer{
    
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
        try logManager.setChallengeLogWithList(with: logList)
    }
    private func rollbackResetChallengeLog() throws {
        try logManager.deleteAllChallengeLogAtLocal()
    }
    
    // Challenge
    private func resetLocalChallenge(stat: StatisticsObject, logList: [ChallengeLog], challengeList: [ChallengeObject]) throws {
        try challengeManager.setChallenge()
        for log in logList {
            try restoreExecutor(stat: stat, challengeLog: log.log_complete, challengeList: challengeList)
        }
    }
    
    private func rollbackResetChallenge() throws {
        try challengeManager.delChallenge(with: userId)
    }
}

//===============================
// MARK: - Restore Challenge
//===============================
extension SyncLocaltoServer{
    
    //-------------------------------
    // Executor
    //-------------------------------
    private func restoreExecutor(stat: StatisticsObject, challengeLog: [Int:Date], challengeList: [ChallengeObject]) throws {
        util.log(.info, location, "Proceed challenge resotre process, target: \(challengeLog.count)", userId)
        
        // restore progress
        for (key, date) in challengeLog {
            let targetChallenge = try restoreTargetChallenge(challengeList: challengeList, challengeId: key, finishDate: date)
            try restoreNextChallenge(challengeList: challengeList, challenge: targetChallenge)
        }
        try updateStatistics()
        util.log(.info, location, "Restore Complete: \n* Applied ChallengeStep: \(challengeStep)", userId)
    }
    
    //-------------------------------
    // Restore: target challenge
    //-------------------------------
    private func restoreTargetChallenge(challengeList: [ChallengeObject], challengeId: Int, finishDate: Date) throws -> ChallengeObject {
        // fetch target cahllenge
        guard let challenge = challengeList.first(where: { $0.chlg_id == challengeId }) else {
            throw SyncLocalError.UnexpectedChallengeProgressRestoreError
        }
        // update challenge & step
        try updateTargetChallenge(object: challenge, finishDate: finishDate)
        updateChallengeStep(type: challenge.chlg_type, step: challenge.chlg_step)
        
        util.log(.info, location, "Restored Target Challenge Complete: restored challengeID = \(challenge.chlg_id)", userId)
        return challenge
    }
    
    //-------------------------------
    // Restore: next challenge
    //-------------------------------
    private func restoreNextChallenge(challengeList: [ChallengeObject], challenge: ChallengeObject) throws {
        // fetch next challenge
        guard let prevChallenge = challengeList.first(where: {
            ( $0.chlg_type == challenge.chlg_type ) && ( $0.chlg_step == challenge.chlg_step + 1 )
        }) else {
            throw SyncLocalError.UnexpectedChallengeProgressRestoreError
        }
        // update challenge
        try updateNextChallenge(object: prevChallenge)
        
        util.log(.info, location, "Restored Next Challenge Complete: restored challengeID = \(prevChallenge.chlg_id)", userId)
    }
    
    //-------------------------------
    // Restore: support
    //-------------------------------
    // update: challenge step
    private func updateChallengeStep(type: ChallengeType, step: Int) {
        self.challengeStep[type.rawValue] = step + 1
    }
    
    // update: challenge object
    private func updateTargetChallenge(object: ChallengeObject, finishDate: Date) throws {
        let updated = ChallengeUpdateDTO(
            challengeId: object.chlg_id,
            userId: userId,
            newStatus: true,
            newLock: false,
            newFinishedAt: finishDate
        )
        try challengeCD.updateChallenge(with: updated)
    }
    
    // update: challenge object
    private func updateNextChallenge(object: ChallengeObject) throws {
        let updated = ChallengeUpdateDTO(
            challengeId: object.chlg_id,
            userId: userId,
            newLock: false
        )
        try challengeCD.updateChallenge(with: updated)
    }
    
    // update: statistics object
    private func updateStatistics() throws {
        let updated = StatUpdateDTO(userId: userId, newChallengeStep: challengeStep)
        try statCD.updateStatistics(with: updated)
        challengeStep = try statCD.getStatisticsForObject(with: userId).stat_chlg_step
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
