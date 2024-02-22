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
    // MARK: - Properties
    //================================
    // for service
    private let util = Utilities()
    private let userCD = UserServicesCoredata()
    private let userFS = UserServicesFirestore()
    private let statCD = StatisticsServicesCoredata()
    private let statFS = StatisticsServicesFirestore()
    private let chlgCD = ChallengeServicesCoredata()
    private let challengeManager = ChallengeManager()
    private let syncLocal = SyncLocaltoServer()
    private let syncServer = SyncServerToLocal()
    private let logManager = LogManager()
    private let maxSyncAttemps = 3
    
    // for component
    private var userId: String
    private var loginDate : Date
    private var userData: UserInfoDTO
    private var userStat: StatLoginDTO
    
    // for log
    private let location = "LoginLoading"
    
    //===============================
    // MARK: - Initializer
    //===============================
    /// `LoginLoadingService` 클래스의 인스턴스를 초기화합니다.
    ///
    /// 이 초기화 과정에서는 다음과 같은 작업이 수행됩니다:
    /// - 현재 날짜와 시간을 기록합니다.
    /// - 사용자 ID를 "Unknown"으로 초기화합니다.
    /// - 사용자 데이터와 통계 데이터를 각각 `UserInfoDTO`와 `StatLoginDTO`의 기본 인스턴스로 초기화합니다.
    ///
    /// 이 과정은 앱 내에서 로그인 과정을 시작하기 위한 기본 설정을 제공합니다.
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
    
    /// 사용자 로그인 프로세스를 실행합니다. 이 과정에서 로컬 데이터 검사, 사용자 필터링, (일간/주간)업데이트 진행여부 및 데이터 검증을 포함합니다.
    /// - Parameter dto: `AuthSocialLoginResDTO` 소셜 로그인 응답 데이터를 담고 있습니다.
    /// - Returns: 로그인 과정을 거친 후의 사용자 정보를 담은 `UserInfoDTO` 를 비동기적으로 반환합니다.
    /// - Throws: `LoginLoadingServiceError`의 경우들을 포함한 여러 에러를 던질 수 있습니다.
    func executor(with dto: AuthSocialLoginResDTO) async throws -> UserInfoDTO {
        // prepare parameters
        self.loginDate = Date()
        self.userId = try extractUserId(from: dto)
        self.logManager.readyParameter(userId: userId, caller: location)
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
        try await processDailyAndWeeklyUpdates(with: loginDate)
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
    
    // ---------- DataInspection: Before ----------
    /// 로컬 데이터 검사를 수행합니다. 필요한 경우 동기화 프로세스를 시작합니다.
    /// - Parameter loginDate: 로그인 시도 날짜입니다.
    /// - Throws: `LoginLoadingServiceError.TooManyLocalSyncAttempt` 로컬 동기화 시도가 너무 많을 경우 발생합니다.
    private func preDataInspection(at loginDate: Date) async throws {
        if !checkLocalData() {
            // case: no local data, need sync process
            util.log(LogLevel.info, location,"No Data at Local Device, Start Synchronize Process", userId)
            try await syncProcess(attemptCount: 0, at: loginDate)
            util.log(LogLevel.info, location,"Synchronize Process Complete", userId)
        }
        // case: verifiy local data
        util.log(LogLevel.info, location,"Local data Verification complete, Continue Login Process", userId)
        self.userData = try UserInfoDTO(with: userCD.getUser(with: userId))
        self.userStat = try statCD.getStatisticsForDTO(with: userId, type: .login) as! StatLoginDTO
    }
    
    // ---------- Filiter ----------
    /// 이전 로그인 시간과 현재 시간을 비교하여 사용자를 필터링합니다. 사용자는 당일 첫 로그인 사용자와 재로그인 사용자로 나뉩니다.
    /// - Returns: 재로그인 사용자는  true, 당일 첫 로그인 사용자는 false를 반환합니다.
    /// - Throws: `LoginLoadingServiceError.EmptyAccessLog` 접속로그가 비어 있을 경우 발생합니다.
    private func userFiliter() throws -> Bool {
        util.log(LogLevel.info, location, "Start Filtering User", userId)
        // check & get access log
        let log = try logManager.getAccessLogAtLocal()
        guard let lastLogin = log.log_access.last else {
            throw LoginLoadingServiceError.EmptyAccessLog
        }
        return util.compareTime(currentTime: loginDate, lastTime: lastLogin)
    }
    
    // ---------- Update Process ----------
    /// 유형(일일, 주간)에 따라 필요한 업데이트 프로세스를 수행합니다. 일일의 경우 통계정보 업데이트를, 주간의 경우 통계정보의 서버 동기화를 진행합니다.
    /// - Parameter loginDate: 업데이트의 기준이 되는 로그인 날짜입니다.
    /// - Throws: `LoginLoadingServiceError.TooManyServerSyncAttempt` 서버 동기화 시도가 너무 많을 경우 발생합니다.
    private func processDailyAndWeeklyUpdates(with loginDate: Date) async throws {
        // daily: service term update
        util.log(LogLevel.info, location, "Start Daily Update: \n* Privious Service Term: \(userStat.term)", userId)
        try await dailyUpdateProcess(with: loginDate)
        util.log(LogLevel.info, location, "Start Daily Update: \n* Applied Service Term: \(userStat.term)", userId)
        
        // Weekly: synchronize
        if isWeeklyUpdateNeed() {
            util.log(LogLevel.info, location, "Weekly-Update Require", userId)
            try updateUploadAt(with: loginDate)
            try await weeklyUpdateProcess(at: loginDate)
        }
    }
    
    // ---------- DataInspection: After ----------
    /// 로그인 후 사용자 데이터와 통계 데이터의 최종 검사를 수행합니다.
    /// - Throws: Coredata에 저장된 데이터를 불러오는 중 에러가 발생할 수 있습니다.
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
    // Check Data
    //--------------------
    /// 로컬에 필요한 모든 데이터가 존재하는지 확인합니다.
    /// - Returns: 모든 데이터(사용자, 통계정보, 접속 로그, 도전과제 로그)가 존재하면 true, 그렇지 않으면 false를 반환합니다.
    private func checkLocalData() -> Bool {
        let dataTypes: [CheckCase] = [.user, .stat, .accessLog, .challengeLog]
        return dataTypes.allSatisfy { doesDataExistInLocal(with: userId, for: $0) }
    }
    
    /// 지정된 유형의 로컬 데이터가 존재하는지 확인합니다.
    /// - Parameters:
    ///   - userId: 사용자 ID입니다.
    ///   - type: 검사할 데이터 유형을 나타내는 `CheckCase` 열거형입니다.
    /// - Returns: 지정된 데이터 유형이 존재하면 true, 그렇지 않으면 false를 반환합니다.
    private func doesDataExistInLocal(with userId: String, for type: CheckCase) -> Bool {
        do {
            switch type {
            case .user:
                let _ = try userCD.getUser(with: userId)
            case .stat:
                let _ = try statCD.getStatisticsForDTO(with: userId, type: .login)
            case .accessLog:
                let _ = try logManager.getAccessLogAtLocal()
            case .challengeLog:
                let _ = try logManager.getChallengeLogAtLocal()
            }
            return true
        } catch {
            util.log(.warning, location, "Local \(type) Data is Not Available: \(error)", userId)
            return false
        }
    }
    
    // Test: Erase All Local Data
    private func resetLocal() throws {
        try userCD.deleteUser(with: userId)
        try statCD.deleteStatistics(with: userId)
        try logManager.deleteAllAccessLogAtLocal()
        try logManager.deleteAllChallengeLogAtLocal()
    }
    
    
    //--------------------
    // Synchronize (Local to Server)
    //--------------------
    /// 로컬 데이터를 서버에 동기화하는 프로세스를 실행합니다.
    /// - Parameters:
    ///   - attemptCount: 현재까지 시도된 동기화 횟수입니다.
    ///   - loginDate: 로그인 시도 날짜입니다.
    /// - Throws: `LoginLoadingServiceError.TooManyLocalSyncAttempt` 동기화 시도가 최대 허용 횟수를 초과할 경우 발생합니다.
    private func syncProcess(attemptCount: Int, at loginDate: Date) async throws {
        do {
            util.log(LogLevel.info, location, "Start Synchronize Local to Server", userId)
            try await syncLocal.syncExecutor(with: loginDate, by: userId)
        } catch {
            util.log(LogLevel.critical, location, "Local Synchronizer Failure", userId)
            if attemptCount >= maxSyncAttemps {
                throw LoginLoadingServiceError.TooManyLocalSyncAttempt
            }
            try await syncProcess(attemptCount: attemptCount + 1, at: loginDate)
        }
    }
    
    
    //--------------------
    // Daily Update
    //--------------------
    /// 일일 업데이트를 진행합니다. 통계정보의 서비스 기간을 업데이트하고 접속로그에 로그인 시간을 기록합니다.
    /// - Parameter loginDate: 로그인 시도 날짜입니다.
    /// - Throws: 업데이트 실패 시 예외를 던집니다.
    private func dailyUpdateProcess(with loginDate: Date) async throws {
        // update & apply serviceTerm at statistics
        try updateServiceTerm()
        util.log(.info, location, "Service Term update complete: ", userId)
        
        // update & apply loginDate at accesslog
        try updateLoginAt(with: loginDate)
        try await logManager.appendAccessLog(with: loginDate)
    }
    
    /// 통계정보의 서비스 기간을 업데이트합니다.
    /// - Throws: 서비스 기간 업데이트 실패 시 예외를 던집니다.
    private func updateServiceTerm() throws {
        // update service parameter
        let newTerm = userStat.term + 1
        userStat.updateServiceTerm(with: newTerm)
        // apply local
        let updated = StatUpdateDTO(userId: userId, newTerm: newTerm)
        try statCD.updateStatistics(with: updated)
    }
    
    /// 사용자정보의 최근 로그인 시간을 업데이트합니다.
    /// - Parameter loginDate: 새로운 로그인 시간입니다.
    /// - Throws: 로그인 시간 업데이트 실패 시 예외를 던집니다.
    private func updateLoginAt(with loginDate: Date) throws {
        // apply local
        let updated = UserUpdateDTO(userId: userId, newLoginAt: loginDate)
        try userCD.updateUser(with: updated)
    }
    
    
    //--------------------
    // Weekly Update
    //--------------------
    /// 주간 업데이트가 필요한지 여부를 결정합니다. 접속일 기준 7일 단위로 필요여부를 판단합니다.
    /// - Returns: 주간 업데이트가 필요한 경우 `true`, 그렇지 않은 경우 `false`를 반환합니다.
    private func isWeeklyUpdateNeed() -> Bool {
        return userStat.term % 7 == 0
    }
    
    /// 주간 업데이트를 진행합니다. 사용자 정보(통계정보/접속 로그/도전과제 로그)를 서버와 동기화합니다.
    /// - Parameters:
    ///   - attempCount: 현재까지 시도된 주간 업데이트 횟수입니다.
    ///   - syncDate: 동기화 시도 날짜입니다.
    /// - Throws: `LoginLoadingServiceError.TooManyServerSyncAttempt` 동기화 시도가 최대 허용 횟수를 초과할 경우 발생합니다
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

    /// 통계정보의 마지막 서버와 동기화 시점을 업데이트 합니다.
    /// - Parameter syncDate: 새로운 동기화 시간입니다.
    /// - Throws: 업로드 시간 업데이트 실패 시 예외를 던집니다.
    private func updateUploadAt(with syncDate: Date) throws {
        let updated = StatUpdateDTO(userId: userId, newUploadAt: syncDate)
        try statCD.updateStatistics(with: updated)
    }
    
    //--------------------
    // Utilities
    //--------------------
    /// 소셜 로그인 결과로부터 사용자 ID를 추출합니다.
    /// - Parameter authResult: 소셜 로그인 응답 데이터입니다.
    /// - Returns: 추출된 사용자 ID입니다.
    /// - Throws: 사용자 ID 추출 실패 시 예외를 던집니다.
    private func extractUserId(from authResult: AuthSocialLoginResDTO) throws -> String {
        return try util.getIdentifier(from: authResult)
    }
}

//================================
// MARK: - Enum
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

/// 로컬 데이터 검사 유형을 나타냅니다.
enum CheckCase: String {
    case user = "UserData"
    case stat = "Statistics"
    case accessLog = "AccessLog"
    case challengeLog = "ChallengeLog"
}
