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
        util.log(LogLevel.info, "LoginLoading", "Service Initilizie Complete", userId)
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
        util.log(LogLevel.info, "LoginLoading", "Login Process Start", userId)
        
        // check & sync local if need
        try await checkAndSyncData(at: loginDate)
        
        // filiter
        if try userFiliter() {
            // re-login user
            util.log(LogLevel.info, "LoginLoading", "Filtering Complete (Re-Login User)", userId)
            return userData
        }
        util.log(LogLevel.info, "LoginLoading", "Filtering Complete (Daily-Update Require)", userId)
        // update & sync server if need
        try await updateAndSyncData(with: loginDate)
        util.log(LogLevel.info, "LoginLoading", "Login Process Complete", userId)
        // data check & return
        try dataCheck()
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
            util.log(LogLevel.info, "LoginLoading",
                     "No Data at Local Device, Start Synchronize with Server", userId)
            syncLocal.readySync(with: userId)
            try await syncProcess(attemptCount: 0, at: loginDate)
        }
        util.log(LogLevel.info, "LoginLoading",
                 "Local data Verification complete, Continue Login Process", userId)
        try getLocalData()
        try self.logManager.readyManager()
    }
    
    // Filiter
    private func userFiliter() throws -> Bool {
        util.log(LogLevel.info, "LoginLoading", "Start Filtering User", userId)
        // check & get access log
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
            util.log(LogLevel.info, "LoginLoading", "Weekly-Update Require", userId)
            try weeklyStatUpdate(with: loginDate)
            try await weeklyUpdateProcess(at: loginDate)
        }
    }
    
    private func dataCheck() throws {
        // User
        util.log(LogLevel.info, "LoginLoading","<---------- UserData Check ---------->", userId)
        print(try userCD.getUser(with: userId))
        print("==========================================")
        
        // Statistics
        util.log(LogLevel.info, "LoginLoading","<---------- Statistics Check ---------->", userId)
        print(try statCD.getStatisticsForObject(with: userId))
        print("==========================================")
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
            util.log(LogLevel.warning, "LoginLoading", "Local UserData is Not Available: \(error)", userId)
            return false
        }
    }
    // Statistics
    func doesStatExistInLocal(with userId: String) -> Bool {
        do {
            let _ = try statCD.getStatisticsForDTO(with: userId, type: .login) as? StatLoginDTO
            return true
        } catch {
            util.log(LogLevel.warning, "LoginLoading", "Local Statistics is Not Available: \(error)", userId)
            return false
        }
    }
    // AccessLog
    func doesAccessLogExistInLocal(with userId: String) -> Bool {
        do {
            let _ = try logManager.getAccessLogAtLocal()
            return true
        } catch {
            util.log(LogLevel.warning, "LoginLoading", "Local AccessLog is Not Available: \(error)", userId)
            return false
        }
    }
    // ChallengeLog
    func doesChallengeLogExistInLocal(with userId: String) -> Bool {
        do {
            let _ = try logManager.getChallengeLogAtLocal()
            return true
        } catch {
            util.log(LogLevel.warning, "LoginLoading", "Local ChallengeLog is Not Available: \(error)", userId)
            return false
        }
    }
    
    //--------------------
    // Sync: Local with Server
    //--------------------
    private func syncProcess(attemptCount: Int, at loginDate: Date) async throws {
        do {
            util.log(LogLevel.info, "LoginLoading", "Start Synchronize Local to Server", userId)
            try await syncLocal.syncExecutor(with: loginDate)
        } catch {
            util.log(LogLevel.critical, "LoginLoading", "Local Synchronizer Failure", userId)
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
        util.log(LogLevel.info, "LoginLoading", "Start Daily Update", userId)
        // update & apply local data
        try dailyStatUpdate()
        try dailyUserUpdate(with: loginDate)
        // update & apply local access log
        try await logManager.addAccessLog(with: loginDate)
    }
    // Weekly
    private func weeklyUpdateProcess(attempCount: Int = 0, at syncDate: Date) async throws {
        do {
            util.log(LogLevel.info, "LoginLoading", "Start Weekly Update", userId)
            syncServer.readySync(with: userId, and: logManager)
            try await syncServer.syncExecutor(with: syncDate)
        } catch {
            util.log(LogLevel.critical, "LoginLoading", "Weekly Update Failure", userId)
            if attempCount >= maxSyncAttemps{
                throw LoginLoadingServiceError.TooManyServerSyncAttempt
            }
            try await weeklyUpdateProcess(attempCount: attempCount + 1, at: syncDate)
        }
    }
    // Update Process: Daily
    private func dailyStatUpdate() throws {
        let newTerm = userStat.term + 1
        userStat.updateServiceTerm(with: newTerm)
        let updated = StatUpdateDTO(userId: userId, newTerm: newTerm)
        try statCD.updateStatistics(with: updated)
    }
    private func dailyUserUpdate(with loginDate: Date) throws {
        let updated = UserUpdateDTO(userId: userId, newLoginAt: loginDate)
        try userCD.updateUser(with: updated)
    }
    
    // Update Process: Weekly
    private func weeklyStatUpdate(with syncDate: Date) throws {
        let updated = StatUpdateDTO(userId: userId, newUploadAt: syncDate)
        try statCD.updateStatistics(with: updated)
    }
    private func weeklyUserUpdate(with updateDate: Date) throws {
        let updated = UserUpdateDTO(userId: userId, newUpdateAt: updateDate)
        try userCD.updateUser(with: updated)
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
