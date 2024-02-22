//
//  SyncServerWithLocal.swift
//  teamplan
//
//  Created by 크로스벨 on 1/10/24.
//  Copyright © 2024 team1os. All rights reserved.
//

import Foundation

final class SyncServerToLocal {
    
    //================================
    // MARK: - Parameter
    //================================
    // for service
    private let userFS = UserServicesFirestore()
    private let userCD = UserServicesCoredata()
    private let statFS = StatisticsServicesFirestore()
    private let statCD = StatisticsServicesCoredata()
    private let accessLogFS = AccessLogServicesFirestore()
    private let accessLogCD = AccessLogServicesCoredata()
    private let challengeLogFS = ChallengeLogServicesFirestore()
    private let challengeLogCD = ChallengeLogServicesCoredata()
    
    private var logManager = LogManager()
    private var userId: String
    private var previousStatUploadAt: Date
    private var accessLogId: Int
    private var previousAccessLogUploadAt: Date
    private var challengeLogId: Int
    private var previousChallengeLogUploadAt: Date
    private var rollbackStack: [() throws -> Void ] = []
    
    // for log
    private let util = Utilities()
    private let location = "SyncServerToLocal"
    
    //===============================
    // MARK: - Initialize
    //===============================
    init() {
        self.userId = "unknown"
        self.previousStatUploadAt = Date()
        self.accessLogId = 0
        self.previousAccessLogUploadAt = Date()
        self.challengeLogId = 0
        self.previousChallengeLogUploadAt = Date()
    }
    
    func readySync(with userId: String, and manager: LogManager) {
        self.userId = userId
        self.logManager = manager
        util.log(.info, location, "Synchronizer Ready", self.userId)
    }
}

//===============================
// MARK: - Executor
//===============================
extension SyncServerToLocal{
    
    func syncExecutor(with syncDate: Date) async throws {
        do {
            util.log(.info, location, "Synchronize Start", userId)
            
            // Statistics
            try await syncStatistics(at: syncDate)
            // AccessLog
            try await syncAccessLog(at: syncDate)
            // ChallengeLog
            try await syncChallengeLog(at: syncDate)
            // Project Log (WIP)
            
        } catch {
            try rollbackAll()
            util.log(.critical, location, "There was an unexpected error while SyncServer: \(error)", userId)
            throw error
        }
    }
    
    private func rollbackAll() throws {
        do {
            for rollback in self.rollbackStack.reversed() {
                try rollback()
            }
        } catch {
            throw error
        }
    }
}

//===============================
// MARK: - Element
//===============================
extension SyncServerToLocal{

    private func syncStatistics(at syncDate: Date) async throws {
        // prepare sync
        let stat = try getStatFromLocal()
        rollbackStack.append(rollbackStatisticsUploadAt)
        // sync process
        try applyStatisticsUploadAt(with: syncDate)
        try await updateServerStatistics(with: stat)
        // clenaup
        util.log(.info, location, "Statistics Synchronize Complete", userId)
        rollbackStack.removeAll()
    }
    
    private func syncAccessLog(at syncDate: Date) async throws {
        // prepare sync
        let accessLog = try getAccessLogFromLocal()
        rollbackStack.append(rollbackAccessLogUploadAt)
        // sync process
        try applyAccessLogUploadAt(with: syncDate)
        try await updateServerAccesslog(with: accessLog, and: syncDate)
        // clenaup
        util.log(.info, location, "AccessLog Synchronize Complete", userId)
        rollbackStack.removeAll()
    }
    
    private func syncChallengeLog(at syncDate: Date) async throws {
        // prepare sync
        let challengeLog = try getChallengeLogFromLocal()
        rollbackStack.append(rollbackChallengeLogUploadAt)
        // sync process
        try applyChallengeLogUploadAt(with: syncDate)
        try await updateServerChallengeLog(with: challengeLog, and: syncDate)
        // clenaup
        util.log(.info, location, "ChallengeLog Synchronize Complete", userId)
        rollbackStack.removeAll()
    }
}

//===============================
// MARK: - SP1: Fetch Local Data
//===============================
extension SyncServerToLocal{
    
    // Statistics
    private func getStatFromLocal() throws -> StatisticsObject {
        let stat = try statCD.getStatisticsForObject(with: userId)
        self.previousStatUploadAt = stat.stat_upload_at
        return stat
    }
    
    // Access Log
    private func getAccessLogFromLocal() throws -> AccessLog {
        let log = try logManager.getAccessLogAtLocal()
        self.accessLogId = log.log_id
        self.previousAccessLogUploadAt = log.log_upload_at
        return log
    }
    
    // Challenge Log
    private func getChallengeLogFromLocal() throws -> ChallengeLog {
        let log = try logManager.getChallengeLogAtLocal()
        self.challengeLogId = log.log_id
        self.previousChallengeLogUploadAt = log.log_upload_at
        return log
    }
    
    // Project Log (WIP)
}

//===============================
// MARK: - SP2: Update Local UploadAt
//===============================
extension SyncServerToLocal{
    
    // Statistics
    private func applyStatisticsUploadAt(with newDate: Date) throws {
        let updated = StatUpdateDTO(userId: userId, newUploadAt: newDate)
        try statCD.updateStatistics(with: updated)
    }
    private func rollbackStatisticsUploadAt() throws {
        let updated = StatUpdateDTO(userId: userId, newUploadAt: previousStatUploadAt)
        try statCD.updateStatistics(with: updated)
    }
    
    // AccessLog
    private func applyAccessLogUploadAt(with syncDate: Date) throws {
        let updated = AccessLogUpdateDTO(userId: userId, logId: accessLogId, newUploadAt: syncDate)
        try accessLogCD.updateLog(with: updated)
    }
    private func rollbackAccessLogUploadAt() throws {
        let updated = AccessLogUpdateDTO(
            userId: userId, logId: accessLogId, newUploadAt: previousAccessLogUploadAt)
        try accessLogCD.updateLog(with: updated)
    }
    
    // ChallengeLog
    private func applyChallengeLogUploadAt(with syncDate: Date) throws {
        let updated = ChallengeLogUpdateDTO(userId: userId, logId: challengeLogId, uploadAt: syncDate)
        try challengeLogCD.updateLog(with: updated)
    }
    private func rollbackChallengeLogUploadAt() throws {
        let updated = ChallengeLogUpdateDTO(
            userId: userId, logId: challengeLogId, uploadAt: previousChallengeLogUploadAt)
        try challengeLogCD.updateLog(with: updated)
    }
    
    // Project Log (WIP)
}

//===============================
// MARK: - SP3: Update Server
//===============================
extension SyncServerToLocal{
    
    // Statistics
    private func updateServerStatistics(with object: StatisticsObject) async throws {
        try await statFS.updateStatistics(with: object)
    }
    
    // Access Log
    private func updateServerAccesslog(with log: AccessLog, and syncDate: Date) async throws {
        try await accessLogFS.updateLog(to: log)
    }
    
    // Challenge Log
    private func updateServerChallengeLog(with log: ChallengeLog, and syncDate: Date) async throws {
        try await challengeLogFS.updateLog(with: log)
    }
    
    // Project Log (WIP)
}
