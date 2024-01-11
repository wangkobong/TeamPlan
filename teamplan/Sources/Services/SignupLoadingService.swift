//
//  SignupLoadingService.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/10/20.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation

final class SignupLoadingService{
    
    let userFS = UserServicesFirestore()
    let userCD = UserServicesCoredata()
    let statFS = StatisticsServicesFirestore()
    let statCD = StatisticsServicesCoredata()
    let aclogFS = AccessLogServicesFirestore()
    let aclogCD = AccessLogServicesCoredata()
    let chlglogFS = ChallengeLogServicesFirestore()
    let chlglogCD = ChallengeLogServicesCoredata()
    let chlgManager = ChallengeManager()
    let logManager = LogManager()
    
    let userId: String
    let signupDate: Date
    var newProfile: UserObject
    var newStat: StatisticsObject
    
    let onboardingChallenge: Int = 100
    
    private var rollbackStack: [() async throws -> Void ] = []
    
    //===============================
    // MARK: - Constructor
    //===============================
    init(newUser: UserSignupDTO){
        self.signupDate = Date()
        self.userId = newUser.userId
        self.newProfile = UserObject(newUser: newUser, signupDate: signupDate)
        self.newStat = StatisticsObject(userId: userId, setDate: signupDate)
        self.logManager.readyParameter(userId: self.userId)
    }
    
    //===============================
    // MARK: - Executor
    //===============================
    // Main Executor
    func executor() async throws -> UserInfoDTO {
        let coredataResult: Bool
        let firestoreResult: Bool
        
        // Execute Coredata
        do {
            coredataResult = try CoredataExecutor()
        } catch {
            print(error)
            coredataResult = false
        }
        // Execute Firestore
        do{
            firestoreResult = try await FirestoreExecutor()
        } catch {
            print(error)
            firestoreResult = false
        }
        
        switch (coredataResult, firestoreResult) {
            
        // Set NewUserPackage at Coredata & Firestore
        case (true, true):
            return UserInfoDTO(with: newProfile)
        
        default:
            try await rollbackAll()
            throw SignupError.UnexpectedSignupError
        }
    }
    
    // Coredata Executor
    func CoredataExecutor() throws -> Bool {
        do {
            // 1. User
            try setUserCD()
            rollbackStack.append(rollbackSetUserCD)
            
            // 2. Statistics
            try setStatisticsCD()
            rollbackStack.append(rollbackSetStatisticsCD)
            
            // 3. AccessLog
            try setNewAccessLogAtLocal()
            rollbackStack.append(rollbackSetNewAccessLogAtLocal)
            
            // 4. ChallengeLog
            try setNewChallengeLogAtLocal()
            rollbackStack.append(rollbackSetNewChallengeLogAtLocal)
            
            rollbackStack.removeAll()
            return true
            
        } catch {
            print("(Service) There was an unexpected error while Execute Set Coredata in 'SignupLoading' : \(error)")
            throw error
        }
    }
    
    // Firestore Executor
    func FirestoreExecutor() async throws -> Bool {
        do {
            // 1. User
            try await setUserFS()
            rollbackStack.append(rollbackSetUserFS)
            
            // 2. Statistics
            try await setStatisticsFS()
            rollbackStack.append(rollbackSetStatisticsFS)
            
            // 3. AccessLog
            try await setNewAccessLogAtServer()
            rollbackStack.append(rollbackSetNewAccessLogAtServer)
            
            // 4. ChallengeLog
            try await setNewChallengeLogAtServer()
            rollbackStack.append(rollbackSetNewChallengeLogAtServer)
            
            // 5. Challenge
            try await setChallenge()
            rollbackStack.append(rollbackSetChallenge)
            
            rollbackStack.removeAll()
            return true
            
        } catch {
            print("(Service) There was an unexpected error while Execute Set Firestore in 'SignupLoading' : \(error)")
            throw error
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
    
    //===============================
    // MARK: - Set User
    //===============================
    // : Firestore
    func setUserFS() async throws {
        try await userFS.setUser(with: newProfile)
    }
    private func rollbackSetUserFS() async throws {
        try await userFS.deleteUser(with: newProfile.user_id)
    }
    
    // : Coredata
    func setUserCD() throws {
        try userCD.setUser(with: newProfile, and: Date())
    }
    private func rollbackSetUserCD() throws {
        try userCD.deleteUser(with: newProfile.user_id)
    }
    
    //===============================
    // MARK: - Set Statistics
    //===============================
    // : Firestore
    func setStatisticsFS() async throws {
        try await statFS.setStatistics(with: newStat)
    }
    private func rollbackSetStatisticsFS() async throws {
        try await statFS.deleteStatistics(with: newProfile.user_id)
    }
    
    // : Coredata
    func setStatisticsCD() throws {
        try statCD.setStatistics(with: newStat)
    }
    private func rollbackSetStatisticsCD() throws {
        try statCD.deleteStatistics(with: newProfile.user_id)
    }
    
    //===============================
    // MARK: - Set AccessLog
    //===============================
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
    
    //===============================
    // MARK: - Set ChallengeLog
    //===============================
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
    
    //===============================
    // MARK: - Set Challenge
    //===============================
    // : Firestore to Coredata
    func setChallenge() async throws {
        try await chlgManager.getChallenges()
        chlgManager.configChallenge(with: newProfile.user_id)
        try chlgManager.setChallenge()
    }
    private func rollbackSetChallenge() throws {
        try chlgManager.delChallenge(with: newProfile.user_id)
    }
}

//===============================
// MARK: - Exception
//===============================
enum SignupError: LocalizedError {
    case UnexpectedSignupError
    
    var errorDescription: String?{
        switch self {
        case .UnexpectedSignupError:
            return "Service: There was an unexpected error while Signup"
        }
    }
}

