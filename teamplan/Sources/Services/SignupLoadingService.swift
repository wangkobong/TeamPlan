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
            coredataResult = try await CoredataExecutor()
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
            
        // Set NewUserPackage only at Coredata
        case (true, false):
            // Update UserStatus
            self.newProfile.setUserStatus(userSatus: .unStableFS)
            try await userCD.updateUser(updatedUser: self.newProfile)
            return UserDTO(userObject: self.newProfile)
            
        // Set NewUserPackage only at Firestore
        case (false, true):
            // Update UserStatus
            self.newProfile.setUserStatus(userSatus: .unStableCD)
            try await userCD.updateUser(updatedUser: self.newProfile)
            return UserDTO(userObject: self.newProfile)
            
        // Failed to Set NewUserPackage at Coredata & Firestore
        case (false, false):
            throw SignupError.UnexpectedSignupError
        }
    }
    
    // Coredata Executor
    func CoredataExecutor() async throws -> Bool {
        do {
            // 1. User
            try await setUserCD()
            rollbackStack.append(rollbackSetUserCD)
            
            // 2. Statistics
            try await setStatisticsCD()
            rollbackStack.append(rollbackSetStatisticsCD)
            
            // 3. AccessLog
            try await setAccessLogCD()
            rollbackStack.append(rollbackSetAccessLogCD)
            
            // 4. ChallengeLog
            try await setChallengeLogCD()
            rollbackStack.append(rollbackSetChallengeLogCD)
            
            //TODO: 5. Challenge : Working Progress
            
            rollbackStack.removeAll()
            return true
            
        } catch {
            try await rollbackAll()
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
            
            rollbackStack.removeAll()
            return true
            
        } catch {
            try await rollbackAll()
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
        try await userFS.deleteUser(identifier: self.newProfile.user_id)
    }
    
    // : Coredata
    func setUserCD() async throws {
        try await userCD.setUser(reqUser: self.newProfile)
    }
    private func rollbackSetUserCD() async throws {
        try await userCD.deleteUser(identifier: self.newProfile.user_id)
    }
    
    //===============================
    // MARK: - Set Statistics
    //===============================
    // : Firestore
    func setStatisticsFS() async throws {
        try await statFS.setStatistics(reqStat: self.newStat)
    }
    private func rollbackSetStatisticsFS() async throws {
        try await statFS.deleteStatistics(identifier: self.newProfile.user_id)
    }
    
    // : Coredata
    func setStatisticsCD() async throws {
        try await statCD.setStatistics(reqStat: self.newStat)
    }
    private func rollbackSetStatisticsCD() async throws {
        try await statCD.deleteStatistics(identifier: self.newProfile.user_id)
    }
    
    //===============================
    // MARK: - Set AccessLog
    //===============================
    // : Firestore
    func setAccessLogFS() async throws {
        try await aclogFS.setAccessLog(reqLog: self.newAccessLog)
    }
    private func rollbackSetAccessLogFS() async throws {
        try await aclogFS.deleteAccessLog(identifier: self.newProfile.user_id)
    }
    
    // : CoreData
    func setAccessLogCD() async throws {
        try await aclogCD.setAccessLog(reqLog: self.newAccessLog)
    }
    private func rollbackSetAccessLogCD() async throws {
        try await aclogCD.deleteAccessLog(identifier: self.newProfile.user_id)
    }
    
    //===============================
    // MARK: - Set ChallengeLog
    //===============================
    // : Firestore
    func setChallengeLogFS() async throws {
        try await chlglogFS.setChallengeLog(reqLog: self.newChallengeLog)
    }
    private func rollbackSetChallengeLogFS() async throws {
        try await chlglogFS.deleteChallengeLog(identifier: self.newProfile.user_id)
    }
    
    // : Coredata
    func setChallengeLogCD() async throws {
        try await chlglogCD.setChallengeLog(reqLog: self.newChallengeLog)
    }
    private func rollbackSetChallengeLogCD() async throws {
        try await chlglogCD.deleteChallengeLog(identifier: self.newProfile.user_id)
    }
    
    //===============================
    // MARK: - Set Challenge
    //===============================
    // Working Progress
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

