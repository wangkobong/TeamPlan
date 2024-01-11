//
//  LoginLoadService.swift
//  teamplan
//
//  Created by 주찬혁 on 11/21/23.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation

final class LoginLoadingService{
    
    //================================
    // MARK: - Parameter
    //================================
    // Service Parameter
    let util = Utilities()
    let userCD = UserServicesCoredata()
    let userFS = UserServicesFirestore()
    let statCD = StatisticsServicesCoredata()
    let statFS = StatisticsServicesFirestore()
    let chlgCD = ChallengeServicesCoredata()
    let challengeManager = ChallengeManager()
    let syncLocal = SynchronizeLocal()
    let syncServer = SynchronizeServer()
    let logManager = LogManager()
    
    // Component Parameter
    var userId: String
    var loginDate : Date
    var userData: UserInfoDTO
    var userStat: StatLoginDTO
    
    // Restore UserData Parameter
    private var rollbackStack: [() throws -> Void ] = []
    
    private let maxSyncAttemps = 3
    
    //===============================
    // MARK: - Initialize
    //===============================
    init(){
        self.loginDate = Date()
        self.userId = "Unknown"
        self.userData = UserInfoDTO()
        self.userStat = StatLoginDTO()
    }
}

//===============================
// MARK: - Main Function
//===============================
extension LoginLoadingService{
    
    func executor(with dto: AuthSocialLoginResDTO) async throws -> UserInfoDTO {
        // ready parameter
        self.loginDate = Date()
        self.userId = try extractUserId(from: dto)
        self.logManager.readyParameter(userId: userId)
        
        // check & sync local if need
        try await checkAndSyncData(at: loginDate)
        
        // filiter
        if try userFiliter() {
            // re-login user
            return userData
        }
        // update & sync server if need
        try await updateAndSyncData(with: loginDate)
        return userData
    }
}

//===============================
// MARK: - Main Element
//===============================
extension LoginLoadingService{
    
    // Check & Local Sync
    private func checkAndSyncData(at loginDate: Date) async throws {
        if !checkLocalData() {
            syncLocal.readySync(with: userId)
            try await syncProcess(attemptCount: 0, at: loginDate)
        }
        try getLocalData()
        try self.logManager.readyManager()
    }
    
    // Filiter
    private func userFiliter() throws -> Bool {
        let log = try logManager.getAccessLogAtLocal()
        guard let lastLogin = log.log_access.last else {
            throw LoginLoadingServiceError.EmptyAccessLog
        }
        return util.compareTime(currentTime: loginDate, lastTime: lastLogin)
    }
    
    // Update & Server Sync
    private func updateAndSyncData(with loginDate: Date) async throws {
        // Daily
        try await dailyUpdateProcess(with: loginDate)
        // Weekly
        if isWeeklyUpdateDue() {
            try updateLocalStatUploadAt(with: loginDate)
            try await weeklyUpdateProcess(at: loginDate)
        }
    }
}


//===============================
// MARK: - Support Function
//===============================
extension LoginLoadingService{
    
    //--------------------
    // Check: Local Data
    //--------------------
    // Signal
    private func checkLocalData() -> Bool {
        let hasUserData = doesUserExistInLocal(with: userId)
        let hasStatData = doesStatExistInLocal(with: userId)
        let hasAccessLogData = doesAccessLogExistInLocal(with: userId)
        let hasChallengeLogData = doesChallengeLogExistInLocal(with: userId)
        
        return hasUserData && hasStatData && hasAccessLogData && hasChallengeLogData
    }
    // User
    private func doesUserExistInLocal(with userId: String) -> Bool {
        do {
            let _ = try userCD.getUser(with: userId)
            return true
        } catch {
            print("Coredata: User Data Not Exist:", error)
            return false
        }
    }
    // Statistics
    func doesStatExistInLocal(with userId: String) -> Bool {
        do {
            let _ = try statCD.getStatisticsForDTO(with: userId, type: .login) as? StatLoginDTO
            return true
        } catch {
            print("Coredata: Statistics Data Not Exist:", error)
            return false
        }
    }
    // AccessLog
    func doesAccessLogExistInLocal(with userId: String) -> Bool {
        do {
            let _ = try logManager.getAccessLogAtLocal()
            return true
        } catch {
            print("Coredata: AccessLog Not Exist:", error)
            return false
        }
    }
    // ChallengeLog
    func doesChallengeLogExistInLocal(with userId: String) -> Bool {
        do {
            let _ = try logManager.getChallengeLogAtLocal()
            return true
        } catch {
            print("Coredata: ChalengeLog Not Exist:", error)
            return false
        }
    }
    
    //--------------------
    // Sync: Local with Server
    //--------------------
    private func syncProcess(attemptCount: Int, at loginDate: Date) async throws {
        do {
            try await syncLocal.syncExecutor(with: loginDate)
        } catch {
            if attemptCount >= maxSyncAttemps {
                throw LoginLoadingServiceError.TooManyLocalSyncAttempt
            }
            try await syncProcess(attemptCount: attemptCount + 1, at: loginDate)
        }
    }
    
    //--------------------
    // Get: Local Data
    //--------------------
    private func getLocalData() throws {
        self.userData = try UserInfoDTO(with: userCD.getUser(with: userId))
        self.userStat = try statCD.getStatisticsForDTO(with: userId, type: .login) as! StatLoginDTO
    }
    
    // Test: Erase All Local Data
    private func resetLocal() throws {
        try userCD.deleteUser(with: userId)
        try statCD.deleteStatistics(with: userId)
        try logManager.deleteAllAccessLogAtLocal()
        try logManager.deleteAllChallengeLogAtLocal()
    }
    
    //--------------------
    // Update Process
    //--------------------
    // Signal
    private func isWeeklyUpdateDue() -> Bool {
        return userStat.term % 7 == 0
    }
    // Daily
    private func dailyUpdateProcess(with loginDate: Date) async throws {
        // update & apply local statistics
        try updateLocalStatTerm()
        // update & apply local access log
        try await logManager.addAccessLog(with: loginDate)
    }
    // Weekly
    private func weeklyUpdateProcess(attempCount: Int = 0, at syncDate: Date) async throws {
        do {
            syncServer.readySync(with: userId, and: logManager)
            try await syncServer.syncExecutor(with: syncDate)
        } catch {
            if attempCount >= maxSyncAttemps{
                throw LoginLoadingServiceError.TooManyServerSyncAttempt
            }
            try await weeklyUpdateProcess(attempCount: attempCount + 1, at: syncDate)
        }
    }
    // Update Process
    private func updateLocalStatTerm() throws {
        let newTerm = userStat.term + 1
        userStat.updateServiceTerm(with: newTerm)
        let updated = StatUpdateDTO(userId: userId, newTerm: newTerm)
        try statCD.updateStatistics(with: updated)
    }
    
    private func updateLocalStatUploadAt(with syncDate: Date) throws {
        let updated = StatUpdateDTO(userId: userId, newUploadAt: syncDate)
        try statCD.updateStatistics(with: updated)
    }
    
    //--------------------
    // Utilities
    //--------------------
    // Extract UserId
    private func extractUserId(from authResult: AuthSocialLoginResDTO) throws -> String {
        return try util.getIdentifier(from: authResult)
    }
}

//================================
// MARK: - Exception
//================================
enum LoginLoadingServiceError: LocalizedError {
    case TooManyLocalSyncAttempt
    case TooManyServerSyncAttempt
    case EmptyAccessLog
    
    var errorDescription: String? {
        switch self {
        case .TooManyLocalSyncAttempt:
            return "Service: There was an Too Many Attempt while Synchronize Local with Server Data"
        case .TooManyServerSyncAttempt:
            return "Service: There was an Too Many Attempt while Synchronize Server with Local Data"
        case .EmptyAccessLog:
            return "Service: Empty Access Log Detected"
        }
    }
}
