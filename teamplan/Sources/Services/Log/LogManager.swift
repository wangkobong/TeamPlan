//
//  LogManager.swift
//  teamplan
//
//  Created by 크로스벨 on 1/8/24.
//  Copyright © 2024 team1os. All rights reserved.
//

import Foundation

final class LogManager{

    //================================
    // MARK: - Parameter
    //================================
    // reference
    let challengeLogCD = ChallengeLogServicesCoredata()
    let challengeLogFS = ChallengeLogServicesFirestore()
    let accessLogCD = AccessLogServicesCoredata()
    let accessLogFS = AccessLogServicesFirestore()
    let projectLogCD = ProjectLogServicesCoredata()
    let projectLogFS = ProjectLogServicesFirestore()
    let statCD = StatisticsServicesCoredata()
    let statFS = StatisticsServicesFirestore()
    
    // private
    private var userId: String
    private var projectId: Int?
    private var logHead: [Int:Int]
    private var challengeLogId: Int
    private var accessLogId: Int
    private let challengeLogLimit = 25000
    private let accessLogLimit = 32000
    private let maxLogCount = 5
    
    // private: for log
    private let util = Utilities()
    private let location = "LogManager"
    private var parent = "unknown"
    
    //===============================
    // MARK: - Initialize
    //===============================
    init(){
        self.userId = "unknown"
        self.projectId = 0
        self.logHead = [:]
        self.accessLogId = 0
        self.challengeLogId = 0
    }
    
    func readyParameter(userId: String, projectId: Int? = nil, caller: String){
        self.userId = userId
        self.projectId = projectId
        self.parent = caller
        util.log(.info, location, "(\(caller)) Parameter Ready! Manager Ready Require!", self.userId)
    }
    
    func readyManager() throws {
        // fetch log head
        logHead = try statCD.getStatisticsForObject(with: userId).stat_log_head
        
        // fetch challenglog id
        guard let challengeLogId = logHead[LogType.challenge.rawValue] else {
            throw LogManagerError.UnexpectedFetchError
        }
        self.challengeLogId = challengeLogId
        
        // fetch accesslog id
        guard let accessLogId = logHead[LogType.access.rawValue] else {
            throw LogManagerError.UnexpectedFetchError
        }
        self.accessLogId = accessLogId
        
        util.log(.info, location, "(\(parent)) Manager Ready! \n* LogHead: \(logHead) \n* AccessLogID: \(self.accessLogId) \n* ChallengeLogID: \(self.challengeLogId)", userId)
    }
}

//================================
// MARK: - Challenge Log
// Main Function
//================================
extension LogManager{
    
    //--------------------
    // Set
    //--------------------
    // new log: local (input -> local)
    func setNewChallengeLogAtLocal(with challengeId: Int, and completeDate: Date) throws {
        let log = ChallengeLog(
            logId: challengeLogId, userId: userId, challengeId: challengeId, completeDate: completeDate)
        try challengeLogCD.setLog(with: log)
    }
    
    // new log: server (local -> server)
    func setNewChallengeLogAtServer() async throws {
        let log = try challengeLogCD.getLog(with: userId, and: challengeLogId)
        try await challengeLogFS.setLog(with: log)
    }
    
    // log list: local (sever -> local)
    func setChallengeLogWithList(with challengeLogList: [ChallengeLog]) throws {
        for log in challengeLogList {
            try challengeLogCD.setLog(with: log)
        }
    }

    //--------------------
    // Get
    //--------------------
    // single log: local
    func getChallengeLogAtLocal() throws -> ChallengeLog {
        return try challengeLogCD.getLog(with: userId, and: challengeLogId)
    }
    
    // single log: server
    func getChallengeLogAtServer() async throws -> ChallengeLog {
        return try await challengeLogFS.getLog(with: userId, and: challengeLogId)
    }
    
    // log list: server
    func getChallengeLogListAtServer() async throws -> [ChallengeLog] {
        return try await challengeLogFS.getLogList(with: userId)
    }

    //--------------------
    // Update
    //--------------------
    // append: local only
    func appendChallengeLog(with challengeId: Int, and completeDate: Date) throws {
        let updated = ChallengeLogUpdateDTO(
            userId: userId,
            logId: challengeLogId,
            challengeId: challengeId,
            updatedAt: completeDate
        )
        try challengeLogCD.updateLog(with: updated)
    }
    
    //--------------------
    // Delete
    //--------------------
    // total log: local
    func deleteAllChallengeLogAtLocal() throws {
        try challengeLogCD.deleteLogList(with: userId)
    }
    // total log: server
    func deleteAllChallengeLogAtServer() async throws {
        try await challengeLogFS.deleteLogList(with: userId)
    }
}

//================================
// MARK: - Access Log
//================================
extension LogManager{
    
    //--------------------
    // Set
    //--------------------
    // new log: local (input -> local)
    func setNewAccessLogAtLocal(with accessDate: Date) throws {
        let log = AccessLog(logId: accessLogId, userId: userId, accessDate: accessDate)
        try accessLogCD.setLog(with: log)
    }
    
    // new log: server (local -> server)
    func setNewAccessLogAtServer() async throws {
        let log = try accessLogCD.getLog(with: userId, and: accessLogId)
        try await accessLogFS.setLog(with: log)
    }
    
    // log list: local (server -> local)
    func setAccessLogAtLocal(with accessLogList: [AccessLog]) throws {
        for log in accessLogList {
            try accessLogCD.setLog(with: log)
        }
    }
    
    //--------------------
    // Get
    //--------------------
    // single log: local
    func getAccessLogAtLocal() throws -> AccessLog {
        return try accessLogCD.getLog(with: userId, and: accessLogId)
    }
    
    // single log: server
    func getAccessLogAtServer() async throws -> AccessLog {
        return try await accessLogFS.getLog(with: userId, and: accessLogId)
    }
    
    // log list: server
    func getAccessLogListAtServer() async throws -> [AccessLog] {
        return try await accessLogFS.getLogList(with: userId)
    }
    
    //--------------------
    // Update
    //--------------------
    // append: local only
    func appendAccessLog(with accessDate: Date) async throws {
        if try shouldCreateNewAccessLog() {
            // new log case
            util.log(LogLevel.info, location, "(\(parent)) Require New AccessLog", userId)
            try await createNewAccessLog(with: accessDate)
        } else {
            // used log case
            try addAccessLog(with: accessDate)
        }
    }
    
    //--------------------
    // Delete
    //--------------------
    func deleteAllAccessLogAtLocal() throws {
        try accessLogCD.deleteLogList(with: userId)
    }
    func deleteAllAccessLogAtServer() async throws {
        try await accessLogFS.deleteLogList(with: userId)
    }
}

//================================
// MARK: - Project Log (WIP)
//================================
extension LogManager{
    
    //--------------------
    // Create
    //--------------------
    
    //--------------------
    // Sync
    //--------------------
}

//================================
// MARK: - Executor
//================================
extension LogManager{
    
    // main executor
    private func accessLogCreateExecutor(with accessDate: Date) async throws {
        // prepare parameter
        let priviousLogId = accessLogId
        accessLogId += 1
        
        // create process
        do {
            try await createNewAccessLog(with: accessDate)
            try await accessLogIdUpdate(with: accessLogId)
            try await manageOutdatedLogs()
            
        } catch {
            // rollback
            accessLogId = priviousLogId
            util.log(.critical, location, "(\(parent)) Unexpected Error while Processing Create New AccessLog: \(error)", userId)
            throw error
        }
    }
    // sub executor
    private func accessLogIdUpdate(with newId: Int) async throws {
        // prepare date parameter
        let uploadAt = Date()
        let previousUploadAt = try statCD.getStatisticsForObject(with: userId).stat_upload_at
        
        // update process
        try updateLocalAccessLog(with: newId, at: uploadAt)
        try await updateServerAccessLog(with: previousUploadAt)
    }
}

//================================
// MARK: - Element
//================================
extension LogManager{
    
    // create process
    private func createNewAccessLog(with accessDate: Date) async throws {
        // create new log at local
        try setNewAccessLogAtLocal(with: accessDate)
        util.log(.info, location, "(\(parent)) Successfully Set New AccessLog at Local", userId)
        // create new log at server
        try await setNewAccessLogAtServer()
        util.log(.info, location, "(\(parent)) Successfully Set New AccessLog at Server", userId)
    }
    
    // update logId ======================================================
    // local
    private func updateLocalAccessLog(with newId: Int, at uploadAt: Date) throws {
        // prepare parameter
        let priviousId = logHead[LogType.access.rawValue]
        
        // update process
        do {
            logHead[LogType.access.rawValue] = newId
            let updatedDTO = StatUpdateDTO(userId: userId, newLogHead: logHead, newUploadAt: uploadAt)
            try statCD.updateStatistics(with: updatedDTO)
            util.log(.info, location, "(\(parent)) Successfully Update Local Statistics AccessLogId", userId)
            
        // rollback process
        } catch {
            logHead[LogType.access.rawValue] = priviousId
            util.log(.critical, location, "(\(parent)) Unexpected Error while Processing Update Local Statistics AccessLogID: \(error)", userId)
        }
    }
    // server
    private func updateServerAccessLog(with previousUploadAt: Date) async throws {
        // prepare parameter
        let updatedObject = try statCD.getStatisticsForObject(with: userId)
        
        // update process
        do {
            try await statFS.updateStatistics(with: updatedObject)
            util.log(.info, location, "(\(parent)) Successfully Update Server Statistics AccessLogId", userId)
            
        // rollback process
        } catch {
            util.log(.critical, location, "(\(parent)) Unexpected Error while Processing Update Server Statistics AccessLogID: \(error)", userId)
            rollbackServerStatistics(to: previousUploadAt)
            throw error
        }
    }
    //======================================================
    
    // manage outdate log
    private func manageOutdatedLogs() async throws {
        if try shouldDeleteOutdatedAccessLog() {
            util.log(LogLevel.info, location, "(\(parent)) Log Limit Excess, Start Delete Outdate Log", userId)
            let outdatedLogId = try extractOutdatedAccessLog()
            try await deleteAccessLog(with: outdatedLogId)
            util.log(LogLevel.info, location, "(\(parent)) Successfully Delete Outdate Log", userId)
        }
    }
    
    // rollback: local
    private func rollbackServerStatistics(to previousUploadAt: Date) {
        let rollbackDTO = StatUpdateDTO(userId: userId, newUploadAt: previousUploadAt)
        do {
            try statCD.updateStatistics(with: rollbackDTO)
        } catch {
            util.log(.critical, location, "(\(parent)) Failed to rollback Server Statistics: \(error)", userId)
        }
    }
}

//================================
// MARK: - Support Function
//================================
extension LogManager{
    // Check: Log Size
    private func shouldCreateNewAccessLog() throws -> Bool {
        let log = try accessLogCD.getLog(with: userId, and: accessLogId)
        return log.log_access.count < accessLogLimit
    }
    
    // Check: Log Count
    private func shouldDeleteOutdatedAccessLog() throws -> Bool {
        let logList = try accessLogCD.getLogList(with: userId)
        return logList.count > maxLogCount
    }
    
    // Get: Outdated LogId
    private func extractOutdatedAccessLog() throws -> Int {
        let logList = try accessLogCD.getLogList(with: userId)
        
        guard let outdatedLogId = logList.map({ $0.log_id }).min() else {
            throw LogManagerError.UnexpectedSearchIdError
        }
        return outdatedLogId
    }
    
    // Delete: Outdated Log
    private func deleteAccessLog(with outdatedLogId: Int) async throws {
        // delete local log
        try accessLogCD.deleteLog(with: userId, and: outdatedLogId)
        // delete server log
        try await accessLogFS.deleteLog(with: userId, and: outdatedLogId)
    }
    
    // Append: Add new Log
    private func addAccessLog(with accessDate: Date) throws {
        var log = try accessLogCD.getLog(with: userId, and: accessLogId)
        log.log_access.append(accessDate)
    }
}

//================================
// MARK: - Enum
//================================
enum LogType: Int{
    case access = 1
    case challenge = 2
}

//================================
// MARK: - Exception
//================================
enum LogManagerError: LocalizedError {
    case UnexpectedSearchIdError
    case UnexpectedSearchLogError
    case UnexpectedFetchError
    
    var errorDescription: String?{
        switch self {
        case .UnexpectedSearchIdError:
            return "Manager: There was an unexpected error while Search Outdated 'Log' ID"
        case .UnexpectedSearchLogError:
            return "Manager: There was an unexpected error while Search Outdated 'Log'"
        case .UnexpectedFetchError:
            return "Manager: There was an unexpected error while Fetch 'LogId' from Statistics"
        }
    }
}


