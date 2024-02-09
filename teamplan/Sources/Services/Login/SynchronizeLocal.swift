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
    // for service
    let util = Utilities()
    let userFS = UserServicesFirestore()
    let userCD = UserServicesCoredata()
    let statFS = StatisticsServicesFirestore()
    let statCD = StatisticsServicesCoredata()
    let challengeCD = ChallengeServicesCoredata()
    let challengeManager = ChallengeManager()
    var logManager = LogManager()
    
    var userId: String
    var challengeStep: [Int:Int] =  [
        ChallengeType.serviceTerm.rawValue : 1,
        ChallengeType.totalTodo.rawValue : 1,
        ChallengeType.projectAlert.rawValue : 1,
        ChallengeType.projectFinish.rawValue : 1,
        ChallengeType.waterDrop.rawValue : 1
    ]
    private var rollbackStack: [() throws -> Void ] = []
    
    // for log
    private let location = "LocalSynchronizer"
    
    
    //===============================
    // MARK: - Initialize
    //===============================
    init(){
        self.userId = "unknown"
    }
    
    func readySync(with userId: String) {
        self.userId = userId
    }
}

//===============================
// MARK: - Main Function
//===============================
extension SynchronizeLocal{
    
    func syncExecutor(with syncDate: Date) async throws {
        do {
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
        try logManager.setChallengeLogWithList(with: logList)
    }
    
    private func rollbackResetChallengeLog() throws {
        try logManager.deleteAllChallengeLogAtLocal()
    }
    
    // Challenge
    private func resetLocalChallenge(stat: StatisticsObject, logList: [ChallengeLog], challengeList: [ChallengeObject]) throws {
        // apply local
        try challengeManager.setChallenge()
        // restore progress
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
        util.log(LogLevel.info, location, "Start Restore Challenge Progress, target: \(challengeLog.count)", userId)
        
        // restore progress
        for (key, date) in challengeLog {
            guard let challenge = challengeList.first(where: { $0.chlg_id == key }) else {
                throw SyncLocalError.UnexpectedChallengeProgressRestoreError
            }
            // apply restore
            try updateChallenge(object: challenge, finishDate: date)
            restoreChallengeStep(type: challenge.chlg_type, step: challenge.chlg_step)
            util.log(LogLevel.info, location, "Restore Challenge Progress Complete: restored challengeID = \(challenge.chlg_id)", userId)
        }
        try updateStatistics()
        util.log(LogLevel.info, location, "Restore Complete: \n* Applied ChallengeStep: \(challengeStep)", userId)
    }
    
    // Restore Challenge Step
    private func restoreChallengeStep(type: ChallengeType, step: Int) {
        self.challengeStep[type.rawValue] = step + 1
    }
    
    // Apply Challenge Update
    private func updateChallenge(object: ChallengeObject, finishDate: Date) throws {
        let updated = ChallengeUpdateDTO(challengeId: object.chlg_id, userId: userId,
                                         newSelected: false, newStatus: true, newLock: false,
                                         newFinishedAt: finishDate
        )
        try challengeCD.updateChallenge(with: updated)
    }
    
    // Apply Statistics Upadte
    private func updateStatistics() throws {
        let updated = StatUpdateDTO(userId: userId, newChallengeStep: challengeStep)
        try statCD.updateStatistics(with: updated)
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
