//
//  SignupLoadingService.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/10/20.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation

final class SignupLoadingService{
    
    //================================
    // MARK: - Parameter
    //================================
    let userFS = UserServicesFirestore()
    let userCD = UserServicesCoredata()
    let statFS = StatisticsServicesFirestore()
    let statCD = StatisticsServicesCoredata()
    let logManager = LogManager()
    let challengeManager = ChallengeManager()
    
    let userId: String
    let signupDate: Date
    var newProfile: UserObject
    var newStat: StatisticsObject
    
    let onboardingChallenge: Int = 100
    
    private var rollbackStack: [() async throws -> Void ] = []
    
    //===============================
    // MARK: - Initialize
    //===============================
    init(newUser: UserSignupDTO){
        self.userId = newUser.userId
        self.signupDate = Date()
        
        self.newProfile = UserObject(
            newUser: newUser, signupDate: signupDate)
        self.newStat = StatisticsObject(
            userId: userId, setDate: signupDate)
        self.logManager.readyParameter(userId: self.userId)
    }
}

//===============================
// MARK: - Main Executor
//===============================
extension SignupLoadingService{
    
    func executor() async throws -> UserInfoDTO {
        // Ready Parameter
        let localSetResult: Bool
        let serverSetResult: Bool
    
        // Local Execute Result
        localSetResult = try localExecutor()
        
        // Server Execute Result
        serverSetResult = try await serverExecutor()
        
        // Apply Execute
        switch (localSetResult, serverSetResult) {
            
        case (true, true):
            return UserInfoDTO(with: newProfile)
            
        default:
            try await rollbackAll()
            throw SignupLoadingError.UnexpectedSignupError
        }
    }
}

//===============================
// MARK: - Support Executor
//===============================
extension SignupLoadingService{
    
    // Local
    private func localExecutor() throws -> Bool {
        do {
            // 1. User
            try setNewUserProfileAtLocal()
            rollbackStack.append(rollbackSetNewUserProfileAtLocal)
            
            // 2. Statistics
            try setNewStatAtLocal()
            rollbackStack.append(rollbackSetNewStatAtLocal)
            
            // Init Log Manager
            try logManager.readyManager()
            
            // 3. AccessLog
            try setNewAccessLogAtLocal()
            rollbackStack.append(rollbackSetNewAccessLogAtLocal)
            
            // 4. ChallengeLog
            try setNewChallengeLogAtLocal()
            rollbackStack.append(rollbackSetNewChallengeLogAtLocal)
            
            rollbackStack.removeAll()
            return true
            
        } catch {
            print("Service: There was an unexpected error while Set New UserData at Local in 'SignupLoadingService'")
            return false
        }
    }
    
    // Server
    private func serverExecutor() async throws -> Bool {
        do {
            // 1. User
            try await setNewUserProfileAtServer()
            rollbackStack.append(rollbackSetNewUserProfileAtServer)
            
            // 2. Statistics
            try await setNewStatAtServer()
            rollbackStack.append(rollbackSetNewStatAtServer)
            
            // 3. AccessLog
            try await setNewAccessLogAtServer()
            rollbackStack.append(rollbackSetNewAccessLogAtServer)
            
            // 4. ChallengeLog
            try await setNewChallengeLogAtServer()
            rollbackStack.append(rollbackSetNewChallengeLogAtServer)
            
            // 5. Challenge
            try await setNewChallengeAtLocal()
            rollbackStack.append(rollbackSetNewChallengeAtLocal)
            
            rollbackStack.removeAll()
            return true
            
        } catch {
            print("Service: There was an unexpected error while Set New UserData at Server in 'SignupLoadingService'")
            return false
        }
    }
    
    private func rollbackAll() async throws {
        do {
            for rollback in rollbackStack.reversed() {
                try await rollback()
            }
            rollbackStack.removeAll()
            
        } catch {
            throw error
        }
    }
}

//===============================
// MARK: - User
//===============================
extension SignupLoadingService{
    
    // : Coredata
    private func setNewUserProfileAtLocal() throws {
        try userCD.setUser(with: newProfile, and: signupDate)
    }
    private func rollbackSetNewUserProfileAtLocal() throws {
        try userCD.deleteUser(with: userId)
    }
    
    // : Firestore
    private func setNewUserProfileAtServer() async throws {
        try await userFS.setUser(with: newProfile)
    }
    private func rollbackSetNewUserProfileAtServer() async throws {
        try await userFS.deleteUser(with: userId)
    }
}

//===============================
// MARK: - Statisticcs
//===============================
extension SignupLoadingService{
    
    // : Coredata
    private func setNewStatAtLocal() throws {
        try statCD.setStatistics(with: newStat)
    }
    private func rollbackSetNewStatAtLocal() throws {
        try statCD.deleteStatistics(with: userId)
    }
    
    // : Firestore
    private func setNewStatAtServer() async throws {
        try await statFS.setStatistics(with: newStat)
    }
    private func rollbackSetNewStatAtServer() async throws {
        try await statFS.deleteStatistics(with: userId)
    }
}

//===============================
// MARK: - AccessLog
//===============================
extension SignupLoadingService{
    
    // : CoreData
    private func setNewAccessLogAtLocal() throws {
        try logManager.setNewAccessLogAtLocal(with: signupDate)
    }
    private func rollbackSetNewAccessLogAtLocal() throws {
        try logManager.deleteAllAccessLogAtLocal()
    }
    
    // : Firestore
    private func setNewAccessLogAtServer() async throws {
        try await logManager.setNewAccessLogAtServer()
    }
    private func rollbackSetNewAccessLogAtServer() async throws {
        try await logManager.deleteAllAccessLogAtServer()
    }
}

//===============================
// MARK: - ChallengeLog
//===============================
extension SignupLoadingService{
    
    // : Coredata
    private func setNewChallengeLogAtLocal() throws {
        try logManager.setNewChallengeLogAtLocal(with: onboardingChallenge, and: signupDate)
    }
    private func rollbackSetNewChallengeLogAtLocal() throws {
        try logManager.deleteAllChallengeLogAtLocal()
    }
    
    // : Firestore
    private func setNewChallengeLogAtServer() async throws {
        try await logManager.setNewChallengeLogAtServer()
    }
    private func rollbackSetNewChallengeLogAtServer() async throws {
        try await logManager.deleteAllChallengeLogAtServer()
    }
}

//===============================
// MARK: - Challenge
//===============================
extension SignupLoadingService{

    // Sync: Server to Local
    private func setNewChallengeAtLocal() async throws {
        try await challengeManager.getChallengesFromServer()
        challengeManager.configChallenge(with: newProfile.user_id)
        try challengeManager.setChallenge()
    }
    private func rollbackSetNewChallengeAtLocal() throws {
        try challengeManager.delChallenge(with: newProfile.user_id)
    }
}

//===============================
// MARK: - Exception
//===============================
enum SignupLoadingError: LocalizedError {
    case UnexpectedSignupError
    
    var errorDescription: String?{
        switch self {
        case .UnexpectedSignupError:
            return "Service: There was an unexpected error while Processing Set NewUser at 'SignupLoadingService'"
        }
    }
}

