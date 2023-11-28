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
    
    var newProfile: UserObject
    var newStat: StatisticsObject
    var newAccessLog: AccessLog
    var newChallengeLog: ChallengeLog
    
    private var rollbackStack: [() async throws -> Void ] = []
    
    //===============================
    // MARK: - Constructor
    //===============================
    init(newUser: UserSignupDTO){
        let signupDate = Date()
        self.newProfile = UserObject(newUser: newUser, signupDate: signupDate)
        self.newStat = StatisticsObject(identifier: newUser.identifier, signupDate: signupDate)
        self.newAccessLog = AccessLog(identifier: newUser.identifier, signupDate: signupDate)
        self.newChallengeLog = ChallengeLog(identifier: newUser.identifier, signupDate: signupDate)
    }
    
    //===============================
    // MARK: - Executor
    //===============================
    // Main Executor
    func executor() async throws -> UserDTO {
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
            return UserDTO(userObject: self.newProfile)
        
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
            try setAccessLogCD()
            rollbackStack.append(rollbackSetAccessLogCD)
            
            // 4. ChallengeLog
            try setChallengeLogCD()
            rollbackStack.append(rollbackSetChallengeLogCD)
            
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
            try await setAccessLogFS()
            rollbackStack.append(rollbackSetAccessLogFS)
            
            // 4. ChallengeLog
            try await setChallengeLogFS()
            rollbackStack.append(rollbackSetChallengeLogFS)
            
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
        let docsId = try await userFS.setUser(reqUser: self.newProfile)
        self.newProfile.user_fb_id = docsId
    }
    private func rollbackSetUserFS() async throws {
        try await userFS.deleteUser(to: self.newProfile.user_id)
    }
    
    // : Coredata
    func setUserCD() throws {
        try userCD.setUser(reqUser: self.newProfile)
    }
    private func rollbackSetUserCD() throws {
        try userCD.deleteUser(identifier: self.newProfile.user_id)
    }
    
    //===============================
    // MARK: - Set Statistics
    //===============================
    // : Firestore
    func setStatisticsFS() async throws {
        try await statFS.setStatistics(reqStat: self.newStat)
    }
    private func rollbackSetStatisticsFS() async throws {
        try await statFS.deleteStatistics(to: self.newProfile.user_id)
    }
    
    // : Coredata
    func setStatisticsCD() throws {
        try statCD.setStatistics(reqStat: self.newStat)
    }
    private func rollbackSetStatisticsCD() throws {
        try statCD.deleteStatistics(identifier: self.newProfile.user_id)
    }
    
    //===============================
    // MARK: - Set AccessLog
    //===============================
    // : Firestore
    func setAccessLogFS() async throws {
        try await aclogFS.setLog(reqLog: self.newAccessLog)
    }
    private func rollbackSetAccessLogFS() async throws {
        try await aclogFS.deleteLog(to: self.newProfile.user_id)
    }
    
    // : CoreData
    func setAccessLogCD() throws {
        try aclogCD.setLog(reqLog: self.newAccessLog)
    }
    private func rollbackSetAccessLogCD() throws {
        try aclogCD.deleteLog(identifier: self.newProfile.user_id)
    }
    
    //===============================
    // MARK: - Set ChallengeLog
    //===============================
    // : Firestore
    func setChallengeLogFS() async throws {
        try await chlglogFS.setLog(reqLog: self.newChallengeLog)
    }
    private func rollbackSetChallengeLogFS() async throws {
        try await chlglogFS.deleteLog(identifier: self.newProfile.user_id)
    }
    
    // : Coredata
    func setChallengeLogCD() throws {
        try chlglogCD.setLog(reqLog: self.newChallengeLog)
    }
    private func rollbackSetChallengeLogCD() throws {
        try chlglogCD.deleteLog(from: self.newProfile.user_id)
    }
    
    //===============================
    // MARK: - Set Challenge
    //===============================
    // : Firestore to Coredata
    func setChallenge() async throws {
        try await chlgManager.setChallenge()
    }
    private func rollbackSetChallenge() throws {
        try chlgManager.delChallenge()
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

