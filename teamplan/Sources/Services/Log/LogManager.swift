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
    let challengeLogCD = ChallengeLogServicesCoredata()
    let challengeLogFS = ChallengeLogServicesFirestore()
    let accessLogCD = AccessLogServicesCoredata()
    let accessLogFS = AccessLogServicesFirestore()
    let projectLogCD = ProjectLogServicesCoredata()
    let projectLogFS = ProjectLogServicesFirestore()
    let statCD = StatisticsServicesCoredata()
    let util = Utilities()
    
    var userId: String
    var projectId: Int?
    var logHead: [Int:Int]
    var challengeLogId: Int
    var accessLogId: Int
    
    private let challengeLogLimit = 25000
    private let accessLogLimit = 32000
    private let maxLogCount = 5
    
    //===============================
    // MARK: - Initialize
    //===============================
    // defualt
    init(){
        self.userId = "unknown"
        self.projectId = 0
        self.logHead = [:]
        self.accessLogId = 0
        self.challengeLogId = 0
    }
    
    func readyParameter(userId: String, projectId: Int? = nil){
        self.userId = userId
        self.projectId = projectId
    }
    
    func readyManager() throws {
        logHead = try statCD.getStatisticsForObject(with: userId).stat_log_head
        // Fetch ChallengeLog ID
        guard let challengeLogId = logHead[LogType.challenge.rawValue] else {
            throw LogManagerError.UnexpectedFetchError
        }
        self.challengeLogId = challengeLogId
        // Fetch AccessLog ID
        guard let accessLogId = logHead[LogType.access.rawValue] else {
            throw LogManagerError.UnexpectedFetchError
        }
        self.accessLogId = accessLogId
    }
}

//================================
// MARK: - Challenge Log
//================================
extension LogManager{
    
    //--------------------
    // Create
    //--------------------
    // Coredata
    func setNewChallengeLogAtLocal(with challengeId: Int, and completeDate: Date) throws {
        let log = ChallengeLog(logId: challengeLogId, userId: userId, challengeId: challengeId, completeDate: completeDate)
        try challengeLogCD.setLog(with: log)
    }
    func setChallengeLogAtLocal(with challengeLogList: [ChallengeLog]) throws {
        for log in challengeLogList {
            try challengeLogCD.setLog(with: log)
        }
    }
    
    // Firestore
    func setNewChallengeLogAtServer() async throws {
        let log = try challengeLogCD.getLog(with: userId, and: challengeLogId)
        try await challengeLogFS.setLog(with: log)
    }
    
    //--------------------
    // Get
    //--------------------
    // Coredata
    func getChallengeLogAtLocal() throws -> ChallengeLog {
        return try challengeLogCD.getLog(with: userId, and: challengeLogId)
    }
    
    // Firestore
    func getChallengeLogAtServer() async throws -> ChallengeLog {
        return try await challengeLogFS.getLog(with: userId, and: challengeLogId)
    }
    func getChallengeLogListAtServer() async throws -> [ChallengeLog] {
        return try await challengeLogFS.getLogList(with: userId)
    }
    
    //--------------------
    // Append
    //--------------------
    func addChallengeLog(with challengeId: Int, and completeDate: Date) throws {
        if try shouldCreateNewChallengeLog() {
            // case: need new log
            try createNewChallengeLog(with: challengeId, and: completeDate)
        } else {
            // case: used log
            try appendChallengeLog(with: challengeId, and: completeDate)
        }
    }

    //--------------------
    // Sync
    //--------------------
    func syncLocalAndServerChallengeLog(with syncDate: Date) async throws {
        // ready log
        var localLog = try challengeLogCD.getLog(with: userId, and: challengeLogId)
        localLog.updateUploadAt(with: syncDate)
        // sync log
        if try await isNewChallengeLogNeed() {
            try await challengeLogFS.setLog(with: localLog)
        } else {
            try await challengeLogFS.updateLog(with: localLog)
        }
        // apply local
        let updated = ChallengeLogUpdateDTO(userId: userId, logId: challengeLogId, uploadAt: syncDate)
        try challengeLogCD.updateLog(with: updated)
    }

    
    //--------------------
    // Delete
    //--------------------
    func deleteAllChallengeLogAtLocal() throws {
        try challengeLogCD.deleteLogList(with: userId)
    }
    
    func deleteAllChallengeLogAtServer() async throws {
        try await challengeLogFS.deleteLogList(with: userId)
    }
}

//================================
// MARK: - Access Log
//================================
extension LogManager{
    
    //--------------------
    // Create
    //--------------------
    // Coredata
    func setNewAccessLogAtLocal(with accessDate: Date) throws {
        let log = AccessLog(logId: accessLogId, userId: userId, accessDate: accessDate)
        try accessLogCD.setLog(with: log)
    }
    func setAccessLogAtLocal(with accessLogList: [AccessLog]) throws {
        for log in accessLogList {
            try accessLogCD.setLog(with: log)
        }
    }
    
    // Firestore
    func setNewAccessLogAtServer() async throws {
        let log = try accessLogCD.getLog(with: userId, and: accessLogId)
        try await accessLogFS.setLog(with: log)
    }
    
    //--------------------
    // Get
    //--------------------
    // Coredata
    func getAccessLogAtLocal() throws -> AccessLog {
        return try accessLogCD.getLog(with: userId, and: accessLogId)
    }
    
    // Firestore
    func getAccessLogAtServer() async throws -> AccessLog {
        return try await accessLogFS.getLog(with: userId, and: accessLogId)
    }
    func getAccessLogListAtServer() async throws -> [AccessLog] {
        return try await accessLogFS.getLogList(with: userId)
    }
    
    //--------------------
    // Append
    //--------------------
    func addAccessLog(with accessDate: Date) async throws {
        if try shouldCreateNewAccessLog() {
            // case: need to create new log
            try await createNewAccessLog(with: accessDate)
        } else {
            // case: used log
            try appendAccessLog(with: accessDate)
        }
    }
    
    //--------------------
    // Sync
    //--------------------
    func syncLocalAndServerAccessLog(with syncDate: Date) async throws {
        // ready log
        var localLog = try accessLogCD.getLog(with: userId, and: accessLogId)
        localLog.updateUploadAt(with: syncDate)
        // sync log
        try await accessLogFS.updateLog(to: localLog)
        // apply local
        let updated = AccessLogUpdateDTO(userId: userId, logId: accessLogId, newUploadAt: syncDate)
        try accessLogCD.updateLog(with: updated)
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
// MARK: - ChallengeLog Support Function
//================================
extension LogManager{
    
    // Check: Log Size
    private func shouldCreateNewChallengeLog() throws -> Bool {
        let log = try challengeLogCD.getLog(with: userId, and: challengeLogId)
        return log.log_complete.count > challengeLogLimit
    }
    
    // Update: Log ID
    private func updateChallengeLogId(newId: Int) throws {
        // apply service
        logHead[LogType.challenge.rawValue] = newId
        challengeLogId = newId
        // apply coredata
        let updated = StatUpdateDTO(userId: userId, newLogHead: logHead)
        try statCD.updateStatistics(with: updated)
    }
    
    // Get: Outdate LogId
    private func extractOutdatedChallengeLog() throws -> Int {
        let logList = try challengeLogCD.getLogList(with: userId)
        
        guard let outdateLogId = logList.map({ $0.log_id }).min() else {
            throw LogManagerError.UnexpectedSearchIdError
        }
        return outdateLogId
    }
    
    // Sync: Signal
    private func isNewChallengeLogNeed() async throws -> Bool {
        let serverLogId = try await challengeLogFS.getLog(with: userId, and: challengeLogId).log_id
        
        if serverLogId == challengeLogId {
            return false
        } else {
            return true
        }
    }
    
    // Excutor: Create New Challenge Log
    private func createNewChallengeLog(with challengeId: Int, and completeDate: Date) throws {
        // update log id
        let newLogId = challengeId + 1
        try updateChallengeLogId(newId: newLogId)
        // set new log at local
        try setNewChallengeLogAtLocal(with: challengeId, and: completeDate)
    }
    
    // Append: Add New Log
    private func appendChallengeLog(with challengeId: Int, and completeDate: Date) throws {
        let updated = ChallengeLogUpdateDTO(userId: userId, logId: challengeLogId, challengeId: challengeId, updatedAt: completeDate)
        try challengeLogCD.updateLog(with: updated)
    }
}

//================================
// MARK: - AccessLog Support Function
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
        return logList.count < maxLogCount
    }
    
    // Update: AccessLogID
    private func updateAccessLogId(newId: Int) throws {
        // apply service
        logHead[LogType.access.rawValue] = newId
        accessLogId = newId
        // apply coredata
        let updated = StatUpdateDTO(userId: userId, newLogHead: logHead)
        try statCD.updateStatistics(with: updated)
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
    
    // Exector: Create New AccessLog
    private func createNewAccessLog(with accessDate: Date) async throws {
        // update LogId
        let newLogId = accessLogId + 1
        try updateAccessLogId(newId: newLogId)
        // add new log at local & server
        try setNewAccessLogAtLocal(with: accessDate)
        try await setNewAccessLogAtServer()
        // check log struct count
        if try shouldDeleteOutdatedAccessLog() {
            // delete outdated log
            let outdatedLogId = try extractOutdatedAccessLog()
            try await deleteAccessLog(with: outdatedLogId)
        }
    }
    
    // Append: Add new Log
    private func appendAccessLog(with accessDate: Date) throws {
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


