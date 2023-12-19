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
    let util = Utilities()
    let userCD = UserServicesCoredata()
    let userFS = UserServicesFirestore()
    let statCD = StatisticsServicesCoredata()
    let statFS = StatisticsServicesFirestore()
    let acclogCD = AccessLogServicesCoredata()
    let acclogFS = AccessLogServicesFirestore()
    
    var loginDate : Date
    var userId: String
    var userData: UserDTO
    var userStat: StatisticsDTO
    var userLog: AccessLog
    
    init(){
        self.loginDate = Date()
        self.userId = ""
        self.userData = UserDTO()
        self.userStat = StatisticsDTO()
        self.userLog = AccessLog()
    }
    
    //===============================
    // MARK: - Executor
    //===============================
    func executor(with authResult: AuthSocialLoginResDTO) async throws -> UserDTO {
        
        // Prepare User Data
        self.userId = try await getIdentifier(from: authResult)
        try await fetchExecutor(from: self.userId)
        
        // Re-Login Process
        if try checkLoginTime(){
            return self.userData
        }
        // First Login Process
        // Update & Adjust Coredata
        self.userStat.updateServiceTerm(to: self.userStat.stat_term + 1)
        try recordLoginTimeAtCoredata()
        
        // Update Firestore (7 Days Term)
        if checkLoginTerm() {
            try await recordLoginTimeAtFirestore()
        }
        return self.userData
    }
    // Support Function (Fetch Parallel)
    private func fetchExecutor(from userId: String) async throws {
        
        async let userData = fetchUser(from: userId)
        async let userStat = fetchStatistics(from: userId)
        async let userLog = fetchLog(from: userId)

        self.userData = try await userData
        self.userStat = try await userStat
        self.userLog = try await userLog
    }
    // Support Function (First Login Check)
    private func checkLoginTime() throws -> Bool {
        // Get LastLogin Info
        guard let lastLogin = self.userLog.log_access.last else {
            throw LoginLoadingServiceError.EmptyAccessLog
        }
        // Compare Time
        return util.compareTime(currentTime: self.loginDate, lastTime: lastLogin)
    }
    // Support Function (ServiceTerm Check)
    private func checkLoginTerm() -> Bool {
        return userStat.stat_term % 7 == 0
    }
}

//================================
// MARK: - Get User
//================================
extension LoginLoadingService{
    
    func getIdentifier(from authResult: AuthSocialLoginResDTO) async throws -> String {
        return try util.getIdentifier(from: authResult)
    }
    
    func fetchUser(from userId: String) async throws -> UserDTO {
        
        // Check Coredata
        if let user = try fetchUserFromCoredata(from: userId) {
            return UserDTO(with: user)
        }
        // Check Firestore
        let user = try await fetchUserFromFirestore(from: userId)
        try setUserToCoredata(data: user)
        return UserDTO(with: user)
    }
    
    private func fetchUserFromCoredata(from userId: String) throws -> UserObject? {
        return try? userCD.getUser(from: userId)
    }
    
    private func fetchUserFromFirestore(from userId: String) async throws -> UserObject {
        return try await userFS.getUser(from: userId)
    }
    
    private func setUserToCoredata(data userData: UserObject) throws {
        try userCD.setUser(reqUser: userData)
    }
}

//================================
// MARK: - Get Statistics
//================================
extension LoginLoadingService{
    
    func fetchStatistics(from userId: String) async throws -> StatisticsDTO {
        
        // Check Coredata
        if let stat = try fetchStatFromCoredata(from: userId) {
            return StatisticsDTO(statObject: stat)
        }
        // Check Firestore
        let stat = try await fetchStatFromFirestore(from: userId)
        try setStatToCoredata(data: stat)
        return StatisticsDTO(statObject: stat)
    }
    
    private func fetchStatFromCoredata(from userId: String) throws -> StatisticsObject? {
        return try? statCD.getStatistics(from: userId)
    }
    
    private func fetchStatFromFirestore(from userId: String) async throws -> StatisticsObject {
        return try await statFS.getStatistics(from: userId)
    }
    
    private func setStatToCoredata(data statData: StatisticsObject) throws {
        try statCD.setStatistics(with: statData)
    }
}

//================================
// MARK: - Get AccessLog
//================================
extension LoginLoadingService{
    
    func fetchLog(from userId: String) async throws -> AccessLog {
        
        // Check Coredata
        if let log = try fetchLogFromCoredata(from: userId) {
            return log
        }
        // Check Firestore
        let log = try await fetchLogFromFirestore(from: userId)
        try setLogToCoredata(data: log)
        return log
    }
    
    private func fetchLogFromCoredata(from userId: String) throws -> AccessLog? {
        return try? acclogCD.getLog(from: userId)
    }
    
    private func fetchLogFromFirestore(from userId: String) async throws -> AccessLog {
        return try await acclogFS.getLog(from: userId)
    }
    
    private func setLogToCoredata(data logData: AccessLog) throws {
        try acclogCD.setLog(reqLog: logData)
    }
}

//================================
// MARK: - Update Data
//================================
extension LoginLoadingService{
    
    func recordLoginTimeAtCoredata() throws {
        
        // Update Statistics
        try statCD.updateStatistics(to: self.userStat)
        
        // Update AccessLog
        try acclogCD.updateLog(from: self.userId, updatedAt: self.loginDate)
    }
    
    func recordLoginTimeAtFirestore() async throws {
        
        // Update Statistics
        try await statFS.updateStatistics(to: StatisticsObject(updatedStat: self.userStat))
        
        // Update AccessLog
        try await acclogFS.updateLog(to: self.userLog)
    }
}

//================================
// MARK: - Exception
//================================
enum LoginLoadingServiceError: LocalizedError {
    case EmptyAccessLog
    
    var errorDescription: String? {
        switch self {
        case .EmptyAccessLog:
            return "AccessLog Not Found"
        }
    }
}
