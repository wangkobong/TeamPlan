//
//  SyncServerWithLocal.swift
//  teamplan
//
//  Created by 크로스벨 on 1/10/24.
//  Copyright © 2024 team1os. All rights reserved.
//

import Foundation

final class SynchronizeServer {
    
    //================================
    // MARK: - Parameter
    //================================
    let userFS = UserServicesFirestore()
    let userCD = UserServicesCoredata()
    let statFS = StatisticsServicesFirestore()
    let statCD = StatisticsServicesCoredata()
    
    var logManager = LogManager()
    var userId: String
    
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
extension SynchronizeServer{
    
    func syncExecutor(with syncDate: Date) async throws {
        do {
            // Statistics
            let stat = try getStatFromLocal()
            try await updateServerStat(with: stat)
            
            // AccessLog
            let accessLog = try getAccessLogFromLocal()
            try await updateServerAccesslog(with: accessLog, and: syncDate)
            
            // ChallengeLog
            let challengeLog = try getChallengeLogFromLocal()
            try await updateServerChallengeLog(with: challengeLog, and: syncDate)
            
            // Project Log (WIP)
        } catch {
            print("(Service) There was an unexpected error while Sync Local to Server UserData at 'LoginLoading' : \(error)")
            throw error
        }
    }
}

//===============================
// MARK: - SP1: Fetch Local Data
//===============================
extension SynchronizeServer{
    
    // Statistics
    private func getStatFromLocal() throws -> StatisticsObject {
        return try statCD.getStatisticsForObject(with: userId)
    }
    
    // Access Log
    private func getAccessLogFromLocal() throws -> AccessLog {
        return try logManager.getAccessLogAtLocal()
    }
    
    // Challenge Log
    private func getChallengeLogFromLocal() throws -> ChallengeLog {
        return try logManager.getChallengeLogAtLocal()
    }
    
    // Project Log (WIP)
}

//===============================
// MARK: - SP2: Apply Local to Server
//===============================
extension SynchronizeServer{
    
    // Statistics
    private func updateServerStat(with object: StatisticsObject) async throws {
        try await statFS.updateStatistics(with: object)
    }
    
    // Access Log
    private func updateServerAccesslog(with log: AccessLog, and syncDate: Date) async throws {
        try await logManager.syncLocalAndServerAccessLog(with: syncDate)
    }
    
    // Challenge Log
    private func updateServerChallengeLog(with log: ChallengeLog, and syncDate: Date) async throws {
        try await logManager.syncLocalAndServerChallengeLog(with: syncDate)
    }
    
    // Project Log (WIP)
}
