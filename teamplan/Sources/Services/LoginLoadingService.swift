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
    let chlgCD = ChallengeServicesCoredata()
    let chlgManager = ChallengeManager()
    let acclogCD = AccessLogServicesCoredata()
    let acclogFS = AccessLogServicesFirestore()
    let chlglogCD = ChallengeLogServicesCoredata()
    let chlglogFS = ChallengeLogServicesFirestore()
    
    // Component Parameter
    var userId: String
    var loginDate : Date
    var userData: UserDTO
    var userStat: StatLoginDTO
    var userLog: AccessLog
    
    // Restore UserData Parameter
    private var rollbackStack: [() throws -> Void ] = []
    
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
        // Extract Identifier
        self.userId = try await getIdentifier(from: dto)
        
        // Local Data Check
        try await checkUserDataFromLocal()
        
        // Get Data from Local
        try localExecutor(from: self.userId)
        
        // ReLogin User Filter
        if try reLoginCheck() {
            return userData
        }
        // (Optional) First Use of Day Only
        updateServiceTerm()
        // Local Update : Daily
        try updateLocalStatistics()
        // Server Update : Weakly
        if isWeeklyUpdateDue() {
            try await updateServerStatistics()
        }
        return userData
    }
    // -----------------------------
    // Step 0. Cehck Local Data
    // -----------------------------
    private func checkUserDataFromLocal() async throws {
        do {
            // For Test: Reset Local Data
            try resetLocal()
            
            // Get Data From Local
            try localExecutor(from: userId)
        } catch {
            // Get Data From Server
            print(error)
            try await serverExecutor()
        }
    }
    
    // Get Data from Server
    private func serverExecutor() async throws {
        do {
            try await restoreExecutor()
        } catch {
            //TODO: Only Have Access Record at FirebaseAuth User
            throw error
        }
    }
    
    // Get Data from Local
    private func localExecutor(from userId: String) throws {

        let userData = try fetchUser(with: userId)
        let userStat = try fetchStatistics(with: userId)
        let userLog = try fetchLog(with: userId)

        self.userData = userData
        self.userStat = userStat
        self.userLog = userLog
    }
    
    // Test Function
    private func resetLocal() throws {
        try userCD.deleteUser(identifier: userId)
        try statCD.deleteStatistics(with: userId)
        try chlgManager.delChallenge(with: userId)
        try acclogCD.deleteLog(with: userId)
        try chlglogCD.deleteLog(with: userId)
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
        userStat.updateServiceTerm(with: userStat.term + 1)
    }
    // -----------------------------
    // Step 2. Update Local Statistics Data (Daily)
    // -----------------------------
    private func updateLocalStatistics() throws {
        // (Local) Update Statistics
        let updated = StatUpdateDTO(userId: userId, newTerm: userStat.term)
        try statCD.updateStatistics(with: updated)
        // (Local) Update AccessLog
        try acclogCD.updateLog(with: userId, when: loginDate)
    }
    // -----------------------------
    // Step 3. Update Local Statistics Data (Weekly)
    // -----------------------------
    private func updateServerStatistics() async throws {
        let uploadStat = try statCD.getStatisticsForObject(with: userId)
        // (Server) Update Statistics
        try await statFS.updateStatistics(with: uploadStat)
        // (Server) Update AccessLog
        try await acclogFS.updateLog(to: try acclogCD.getLog(with: userId))
    }
    // -----------------------------
    // Support Function
    // -----------------------------
    private func isWeeklyUpdateDue() -> Bool {
        return userStat.term % 7 == 0
    }
}

//================================
// MARK: - Get User
//================================
extension LoginLoadingService{
    
    func getIdentifier(from authResult: AuthSocialLoginResDTO) async throws -> String {
        return try util.getIdentifier(from: authResult)
    }
    
    func fetchUser(with userId: String) throws -> UserDTO {
        
        // Check Coredata
        guard let user = try fetchUserFromCoredata(with: userId) else {
            throw LoginLoadingServiceError.UnexpectedUserFetchFailed
        }
        return UserDTO(with: user)
    }
    
    private func fetchUserFromCoredata(with userId: String) throws -> UserObject? {
        return try? userCD.getUser(from: userId)
    }
}

//================================
// MARK: - Get Statistics
//================================
extension LoginLoadingService{
    
    func fetchStatistics(with userId: String) throws -> StatLoginDTO {
        
        // Check Coredata
        guard let stat = try fetchStatFromCoredata(with: userId) else {
            throw LoginLoadingServiceError.UnexpectedStatFetchFailed
        }
        return stat
    }
    
    private func fetchStatFromCoredata(with userId: String) throws -> StatLoginDTO? {
        return try statCD.getStatisticsForDTO(with: userId, type: .login) as? StatLoginDTO
    }
}

//================================
// MARK: - Get AccessLog
//================================
extension LoginLoadingService{
    
    func fetchLog(with userId: String) throws -> AccessLog {
        
        // Check Coredata
        guard let log = try fetchLogFromCoredata(with: userId) else {
            throw LoginLoadingServiceError.UnexpectedLogFetchFailed
        }
        return log
    }
    
    private func fetchLogFromCoredata(with userId: String) throws -> AccessLog? {
        return try? acclogCD.getLog(with: userId)
    }
}

//================================
// MARK: - Restore UserData
//================================
extension LoginLoadingService{
    
    private func restoreExecutor() async throws {
        do {
            // User
            let user = try await getUserFS()
            try setUserCD(with: user)
            rollbackStack.append(rollbackSetUserCD)
            
            // Statistics
            let stat = try await getStatFS()
            try setStatCD(with: stat)
            rollbackStack.append(rollbackSetStatCD)
            
            // Access Log
            let accLog = try await getAccLogFS()
            try setAccLogCD(with: accLog)
            rollbackStack.append(rollbackSetAccLogCD)
            
            // Challenge Log
            let chlgLog = try await getChlgLogFS()
            try setChlgLogCD(with: chlgLog)
            rollbackStack.append(rollbackSetChlgLogCD)
            
            // Challenge
            let chlgArray = try await getChlgFS()
            try setChlgCD()
            try restoreUserProgress(stat: stat, ary: chlgArray, log: chlgLog.log_complete)
            
            rollbackStack.removeAll()
            
        } catch {
            try rollbackAll()
            print("(Service) There was an unexpected error while Fetch UserData at 'LoginLoading' : \(error)")
            throw error
        }
    }
    
    private func rollbackAll() throws {
        do {
            for rollback in rollbackStack.reversed() {
                try rollback()
            }
            rollbackStack.removeAll()
        } catch {
            throw error
        }
    }

    // -----------------------------
    // Fetch Data from Firestore
    // -----------------------------
    // User
    private func getUserFS() async throws -> UserObject {
        return try await userFS.getUser(from: userId)
    }
    
    // -----------------------------
    // Statistics
    private func getStatFS() async throws -> StatisticsObject {
        return try await statFS.getStatistics(from: userId)
    }
    
    // -----------------------------
    // Challenge
    private func getChlgFS() async throws -> [ChallengeObject] {
        try await chlgManager.getChallenges()
        chlgManager.configChallenge(with: userId)
        return try chlgManager.getChallenge()
    }
    
    // -----------------------------
    // Access Log
    private func getAccLogFS() async throws -> AccessLog {
        return try await acclogFS.getLog(with: userId)
    }
    
    // -----------------------------
    // Challenge Log
    private func getChlgLogFS() async throws -> ChallengeLog {
        return try await chlglogFS.getLog(with: userId)
    }
    
    
    // -----------------------------
    // Set Data at Coredata
    // -----------------------------
    // User
    private func setUserCD(with object: UserObject) throws {
        try userCD.setUser(reqUser: object)
    }
    
    private func rollbackSetUserCD() throws {
        try userCD.deleteUser(identifier: userId)
    }
    
    // -----------------------------
    // Statistics
    private func setStatCD(with object: StatisticsObject) throws {
        try statCD.setStatistics(with: object)
    }
    
    private func rollbackSetStatCD() throws {
        try statCD.deleteStatistics(with: userId)
    }
    
    // -----------------------------
    // Challenge
    private func setChlgCD() throws {
        try chlgManager.setChallenge()
    }
    
    private func rollbackSetChlgCD() throws {
        try chlgCD.deleteChallenges(with: userId)
    }

    // -----------------------------
    // Access Log
    private func setAccLogCD(with log: AccessLog) throws {
        try acclogCD.setLog(with: log)
    }
    
    private func rollbackSetAccLogCD() throws {
        try acclogCD.deleteLog(with: userId)
    }
    
    // -----------------------------
    // Challenge Log
    private func setChlgLogCD(with log: ChallengeLog) throws {
        try chlglogCD.setLog(with: log)
    }
    
    private func rollbackSetChlgLogCD() throws {
        try chlglogCD.deleteLog(with: userId)
    }
    
    // -----------------------------
    // Support Function
    // -----------------------------
    private func restoreUserProgress(stat: StatisticsObject, ary: [ChallengeObject], log: [Int : Date]) throws {
        
        // Check Log
        guard !log.isEmpty else {
            throw LoginLoadingServiceError.UnexpectedLogFetchFailed
        }
        
        // Update Challenge Status with Log
        for (key, date) in log {
            guard let challenge = ary.first(where: { $0.chlg_id == key }) else {
                throw LoginLoadingServiceError.UnexpectedChallengeFetchFailed
            }
            var updated = ChallengeStatusDTO(with: challenge)
            updated.updateLock(with: false)
            updated.updateStatus(with: true)
            updated.updateFinishedAt(with: date)
            try chlgCD.updateChallenge(with: updated)
            print(updated)
        }
    }
}

//================================
// MARK: - Exception
//================================
enum LoginLoadingServiceError: LocalizedError {
    case UnexpectedUserFetchFailed
    case UnexpectedStatFetchFailed
    case UnexpectedChallengeFetchFailed
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
            return "Service: There was an unexpected error while Fetch 'Challenge' details"
        case .UnexpectedChallengeFetchFailed:
            return "Service: There was an unexpected error while Fetch 'Log' details"
        case .EmptyAccessLog:
            return "AccessLog Not Found"
        case .EmptyStatistics:
            return "Statistics Not Found"
        }
    }
}
