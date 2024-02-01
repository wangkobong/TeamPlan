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
    // for service
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
    
    private let maxSyncAttemps = 3
    
    // for component
    private var userId: String
    private var loginDate : Date
    private var userData: UserInfoDTO
    private var userStat: StatLoginDTO
    
    // for log
    private let location = "LoginLoading"
    
    //===============================
    // MARK: - Initialize
    //===============================
    init(){
        self.loginDate = Date()
        self.userId = "Unknown"
        self.userData = UserInfoDTO()
        self.userStat = StatLoginDTO()
        util.log(LogLevel.info, location, "Service Initilizie Complete", userId)
    }
}

//===============================
// MARK: - Executor
//===============================
extension LoginLoadingService{
    
    func executor(with dto: AuthSocialLoginResDTO) async throws -> UserInfoDTO {
        // prepare parameters
        self.loginDate = Date()
        self.userId = try extractUserId(from: dto)
        self.logManager.readyParameter(userId: userId)
        util.log(LogLevel.info, location, "Login Process Start", userId)
        
        // Step1. data inspection
        try await preDataInspection(at: loginDate)
        try self.logManager.readyManager()
        
        // Step2. user filitering
        if try userFiliter() {
            // re-login user
            util.log(LogLevel.info, location, "Filtering Complete (Re-Login User)", userId)
            return userData
        }
        util.log(LogLevel.info, location, "Filtering Complete (Update Require)", userId)
        
        // Step3. classify update type
        try await updateSorter(with: loginDate)
        util.log(LogLevel.info, location, "Login Process Complete", userId)
        
        // Step4. data inspection
        try afterDataInsepction()
        return userData
    }
}

//===============================
// MARK: - Element
//===============================
extension LoginLoadingService{
    
    // inspection local data
    private func preDataInspection(at loginDate: Date) async throws {
        if !checkLocalData() {
            // case: no local data, need sync process
            syncLocal.readySync(with: userId)
            util.log(LogLevel.info, location,"No Data at Local Device, Start Synchronize Process", userId)
            try await syncProcess(attemptCount: 0, at: loginDate)
            util.log(LogLevel.info, location,"Synchronize Process Complete", userId)
        }
        // case: verifiy local data
        util.log(LogLevel.info, location,"Local data Verification complete, Continue Login Process", userId)
        try getLocalData()
    }
    
    // Filiter
    private func userFiliter() throws -> Bool {
        util.log(LogLevel.info, location, "Start Filtering User", userId)
        // check & get access log
        let log = try logManager.getAccessLogAtLocal()
        guard let lastLogin = log.log_access.last else {
            throw LoginLoadingServiceError.EmptyAccessLog
        }
        return util.compareTime(currentTime: loginDate, lastTime: lastLogin)
    }
    
    // classify update types
    private func updateSorter(with loginDate: Date) async throws {
        // daily: service term update
        util.log(LogLevel.info, location, "Start Daily Update: \n* Privious Service Term: \(userStat.term)", userId)
        try await dailyUpdateProcess(with: loginDate)
        util.log(LogLevel.info, location, "Start Daily Update: \n* Applied Service Term: \(userStat.term)", userId)
        
        // Weekly: synchronize
        if isWeeklyUpdateDue() {
            util.log(LogLevel.info, location, "Weekly-Update Require", userId)
            try updateUploadAt(with: loginDate)
            try await weeklyUpdateProcess(at: loginDate)
        }
    }
    
    private func afterDataInsepction() throws {
        // User
        util.log(LogLevel.info, location," !!!!! Login UserData Insepction !!!!! ", userId)
        let userProfile = try userCD.getUser(with: userId)
        var logOutput = """
            * ID: \(userProfile.user_id)
            * Email: \(userProfile.user_email)
            * NickName: \(userProfile.user_name)
            * Status: \(userProfile.user_status)
            * CreateAt: \(userProfile.user_created_at)
            * LoginAt: \(userProfile.user_login_at)
            * UpdateAt: \(userProfile.user_updated_at)
            """
        print(logOutput)
        
        // Statistics
        util.log(LogLevel.info, location," !!!!! Login User Statistics Insepction !!!!! ", userId)
        let userStat = try statCD.getStatisticsForObject(with: userId)
        logOutput = """
        * ID: \(userStat.stat_user_id)
        * serviceTerm: \(userStat.stat_term)
        * waterDrop: \(userStat.stat_drop)
        * registProject: \(userStat.stat_proj_reg)
        * finishedProject: \(userStat.stat_proj_fin)
        * alertedProject: \(userStat.stat_proj_alert)
        * extendedProject: \(userStat.stat_proj_ext)
        * registedTodo: \(userStat.stat_todo_reg)
        * todoLimit: \(userStat.stat_todo_limit)
        * challengeStep: \(userStat.stat_chlg_step)
        * logID: \(userStat.stat_log_head)
        * uploadServerAt: \(userStat.stat_upload_at)
        """
        print(logOutput)
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
            util.log(LogLevel.warning, location, "Local UserData is Not Available: \(error)", userId)
            return false
        }
    }
    // Statistics
    func doesStatExistInLocal(with userId: String) -> Bool {
        do {
            let _ = try statCD.getStatisticsForDTO(with: userId, type: .login) as? StatLoginDTO
            return true
        } catch {
            util.log(LogLevel.warning, location, "Local Statistics is Not Available: \(error)", userId)
            return false
        }
    }
    // AccessLog
    func doesAccessLogExistInLocal(with userId: String) -> Bool {
        do {
            let _ = try logManager.getAccessLogAtLocal()
            return true
        } catch {
            util.log(LogLevel.warning, location, "Local AccessLog is Not Available: \(error)", userId)
            return false
        }
    }
    // ChallengeLog
    func doesChallengeLogExistInLocal(with userId: String) -> Bool {
        do {
            let _ = try logManager.getChallengeLogAtLocal()
            return true
        } catch {
            util.log(LogLevel.warning, location, "Local ChallengeLog is Not Available: \(error)", userId)
            return false
        }
    }
    
    //--------------------
    // Sync: Local with Server
    //--------------------
    private func syncProcess(attemptCount: Int, at loginDate: Date) async throws {
        do {
            util.log(LogLevel.info, location, "Start Synchronize Local with Server", userId)
            try await syncLocal.syncExecutor(with: loginDate)
        } catch {
            util.log(LogLevel.critical, location, "Local Synchronizer Failure", userId)
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
    // standard
    private func isWeeklyUpdateDue() -> Bool {
        return true
        //return userStat.term % 7 == 0
    }
    
    // daily
    private func dailyUpdateProcess(with loginDate: Date) async throws {
        // update & apply local data
        try updateServiceTerm()
        util.log(.info, location, "Service Term update complete: ", userId)
        
        try updateLoginAt(with: loginDate)
        // update & apply local access log
        try await logManager.appendAccessLog(with: loginDate)
    }
    
    // weekly
    private func weeklyUpdateProcess(attempCount: Int = 0, at syncDate: Date) async throws {
        do {
            util.log(.info, location, "Start Weekly Update", userId)
            syncServer.readySync(with: userId, and: logManager)
            try await syncServer.syncExecutor(with: syncDate)
        } catch {
            util.log(.critical, location, "Weekly Update Failure", userId)
            if attempCount >= maxSyncAttemps{
                throw LoginLoadingServiceError.TooManyServerSyncAttempt
            }
            try await weeklyUpdateProcess(attempCount: attempCount + 1, at: syncDate)
        }
    }

    // service term: daily
    private func updateServiceTerm() throws {
        // update service parameter
        let newTerm = userStat.term + 1
        userStat.updateServiceTerm(with: newTerm)
        // apply local
        let updated = StatUpdateDTO(userId: userId, newTerm: newTerm)
        try statCD.updateStatistics(with: updated)
    }
    
    // loginAt: daily
    private func updateLoginAt(with loginDate: Date) throws {
        // apply local
        let updated = UserUpdateDTO(userId: userId, newLoginAt: loginDate)
        try userCD.updateUser(with: updated)
    }
    
    // statistics uploadAt: weekly
    private func updateUploadAt(with syncDate: Date) throws {
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
