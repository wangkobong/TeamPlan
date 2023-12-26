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
    // MARK: - Parameter Setting
    //================================
    // Service Parameter
    let util = Utilities()
    let userCD = UserServicesCoredata()
    let userFS = UserServicesFirestore()
    let statCD = StatisticsServicesCoredata()
    let statFS = StatisticsServicesFirestore()
    let acclogCD = AccessLogServicesCoredata()
    let acclogFS = AccessLogServicesFirestore()
    
    // Component Parameter
    var userId: String
    var loginDate : Date
    var userData: UserDTO
    var userStat: StatLoginDTO
    var userLog: AccessLog
    
    // Update Parameter
    var userStatUpdate: StatUpdateDTO?
    
    init(){
        self.loginDate = Date()
        self.userId = ""
        self.userData = UserDTO()
        self.userStat = StatLoginDTO()
        self.userLog = AccessLog()
    }
    
    //===============================
    // MARK: - Executor
    //===============================
    func executor(with dto: AuthSocialLoginResDTO) async throws -> UserDTO {
        
        // Step1. Prepare User Data
        self.userId = try await getIdentifier(from: dto)
        try await fetchExecutor(from: self.userId)
        
        // Step2. ReLogin User Filter
        if try reLoginCheck() {
            return userData
        }
        
        // (Optional) First Use of Day Only
        updateServiceTerm()
        // Coredata Update : Daily
        try updateLocalStatistics()
        // Firestore Update : Weakly
        if isWeeklyUpdateDue() {
            try await updateServerStatistics()
        }
        return userData
    }
    // -----------------------------
    // Step 0. Fetch User Data
    // -----------------------------
    private func fetchExecutor(from userId: String) async throws {
        
        async let userData = fetchUser(with: userId)
        async let userStat = fetchStatistics(with: userId)
        async let userLog = fetchLog(with: userId)

        self.userData = try await userData
        self.userStat = try await userStat
        self.userLog = try await userLog
        self.userStatUpdate = StatUpdateDTO(loginDTO: self.userStat)
    }
    // -----------------------------
    // Step 1. Revisit User Check
    // -----------------------------
    private func reLoginCheck() throws -> Bool {
        guard let lastLogin = userLog.log_access.last else {
            throw LoginLoadingServiceError.EmptyAccessLog
        }
        return util.compareTime(currentTime: loginDate, lastTime: lastLogin)
    }
    // -----------------------------
    // Step 1-1. Update Servcie Term
    // -----------------------------
    private func updateServiceTerm() {
        userStat.updateServiceTerm(with: userStat.stat_term + 1)
    }
    // -----------------------------
    // Step 2. Update Local Statistics Data (Daily)
    // -----------------------------
    private func updateLocalStatistics() throws {
        // (Local) Update Statistics
        try statCD.updateStatistics(with: StatUpdateDTO(loginDTO: userStat))
        // (Local) Update AccessLog
        try acclogCD.updateLog(with: userId, when: loginDate)
    }
    // -----------------------------
    // Step 3. Update Local Statistics Data (Weekly)
    // -----------------------------
    private func updateServerStatistics() async throws {
        guard let updateStat = userStatUpdate else {
            throw LoginLoadingServiceError.EmptyStatistics
        }
        // (Server) Update Statistics
        try await statFS.updateStatistics(with: updateStat)
        // (Server) Update AccessLog
        try await acclogFS.updateLog(to: try acclogCD.getLog(with: userId))
    }
    // -----------------------------
    // Support Function
    // -----------------------------
    private func isWeeklyUpdateDue() -> Bool {
        return userStat.stat_term % 7 == 0
    }
}

//================================
// MARK: - Fetch User
//================================
extension LoginLoadingService{
    
    func getIdentifier(from authResult: AuthSocialLoginResDTO) async throws -> String {
        return try util.getIdentifier(from: authResult)
    }
    
    func fetchUser(with userId: String) async throws -> UserDTO {
        
        // Check Coredata
        if let localUser = try fetchUserFromCoredata(with: userId) {
            return UserDTO(with: localUser)
        }
        // Check Firestore
        let serverUser = try await fetchUserFromFirestore(with: userId)
        try setUserToCoredata(with: serverUser)
        return UserDTO(with: serverUser)
    }
    
    private func fetchUserFromCoredata(with userId: String) throws -> UserObject? {
        return try? userCD.getUser(from: userId)
    }
    
    private func fetchUserFromFirestore(with userId: String) async throws -> UserObject {
        return try await userFS.getUser(from: userId)
    }
    
    private func setUserToCoredata(with userData: UserObject) throws {
        try userCD.setUser(reqUser: userData)
    }
}

//================================
// MARK: - Get Statistics
//================================
extension LoginLoadingService{
    
    func fetchStatistics(with userId: String) async throws -> StatLoginDTO {
        
        // Check Coredata
        if let localStat = try fetchStatFromCoredata(with: userId) {
            return localStat
        }
        // Check Firestore
        let serverStat = try await fetchStatFromFirestore(with: userId)
        try setStatToCoredata(with: serverStat)
        return StatLoginDTO(with: serverStat)
    }
    
    private func fetchStatFromCoredata(with userId: String) throws -> StatLoginDTO? {
        return try statCD.getStatisticsForDTO(with: userId, type: .login) as? StatLoginDTO
    }
    
    private func fetchStatFromFirestore(with userId: String) async throws -> StatisticsObject {
        return try await statFS.getStatistics(from: userId)
    }
    
    private func setStatToCoredata(with statData: StatisticsObject) throws {
        try statCD.setStatistics(with: statData)
    }
}

//================================
// MARK: - Get AccessLog
//================================
extension LoginLoadingService{
    
    func fetchLog(with userId: String) async throws -> AccessLog {
        
        // Check Coredata
        if let localLog = try fetchLogFromCoredata(with: userId) {
            return localLog
        }
        // Check Firestore
        let serverLog = try await fetchLogFromFirestore(with: userId)
        try setLogToCoredata(with: serverLog)
        return serverLog
    }
    
    private func fetchLogFromCoredata(with userId: String) throws -> AccessLog? {
        return try? acclogCD.getLog(with: userId)
    }
    
    private func fetchLogFromFirestore(with userId: String) async throws -> AccessLog {
        return try await acclogFS.getLog(with: userId)
    }
    
    private func setLogToCoredata(with logData: AccessLog) throws {
        try acclogCD.setLog(with: logData)
    }
}

//================================
// MARK: - Exception
//================================
enum LoginLoadingServiceError: LocalizedError {
    case UnexpectedUserFetchFailed
    case UnexpectedStatFetchFailed
    case UnexpectedLogFetchFailed
    case EmptyAccessLog
    case EmptyStatistics
    
    var errorDescription: String? {
        switch self {
        case .UnexpectedUserFetchFailed:
            return "Service: There was an unexpected error while Fetch 'User' details"
        case .UnexpectedStatFetchFailed:
            return "Service: There was an unexpected error while Fetch 'Statistics' details"
        case .UnexpectedLogFetchFailed:
            return "Service: There was an unexpected error while Fetch 'Log' details"
        case .EmptyAccessLog:
            return "AccessLog Not Found"
        case .EmptyStatistics:
            return "Statistics Not Found"
        }
    }
}
