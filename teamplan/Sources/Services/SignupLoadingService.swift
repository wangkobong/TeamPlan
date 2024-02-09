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
    // reference
    let util = Utilities()
    let userFS = UserServicesFirestore()
    let userCD = UserServicesCoredata()
    let statFS = StatisticsServicesFirestore()
    let statCD = StatisticsServicesCoredata()
    let logManager = LogManager()
    let challengeManager = ChallengeManager()
    let onboardingChallenge: Int = 100

    // private
    private let userId: String
    private let signupDate: Date
    private var newProfile: UserObject
    private var newStat: StatisticsObject
    private var rollbackStack: [() async throws -> Void ] = []
    
    // private: for log
    private let location = "SignupLoading"
    
    //===============================
    // MARK: - Initialize
    //===============================
    init(newUser: UserSignupDTO){
        self.userId = newUser.userId
        self.signupDate = Date()
        self.newProfile = UserObject(newUser: newUser, signupDate: signupDate)
        self.newStat = StatisticsObject(userId: userId, setDate: signupDate)
        self.logManager.readyParameter(userId: self.userId, caller: location)
        util.log(.info, location, "Ready for Signup Process", self.userId)
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
        
        // Pre-DataInspection
        util.log(.info, location, "Proceed Pre-DataInspection", userId)
        dataInspection(with: self.newProfile)
    
        // Local Execute Result
        localSetResult = try localExecutor()
        util.log(.info, location, "Proceed Local DataInspection", userId)
        dataInspection(with: try userCD.getUser(with: userId))
        
        // Server Execute Result
        serverSetResult = try await serverExecutor()
        util.log(.info, location, "Proceed Server DataInspection", userId)
        dataInspection(with: try await userFS.getUser(from: userId))
        
        // Apply Execute
        switch (localSetResult, serverSetResult) {
            
        case (true, true):
            util.log(.info, location, "Successfully set new-userdata at local & server", userId)
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
        util.log(.info, location, "Proceed storage new-userdata at local device", userId)
        do {
            // 1. User
            try setNewUserProfileAtLocal()
            rollbackStack.append(rollbackSetNewUserProfileAtLocal)
            util.log(.info, location, "Successfully set profile at local", userId)
            
            // 2. Statistics
            try setNewStatAtLocal()
            rollbackStack.append(rollbackSetNewStatAtLocal)
            util.log(.info, location, "Successfully set statistics at local", userId)
            
            // Init Log Manager
            try logManager.readyManager()
            
            // 3. AccessLog
            try setNewAccessLogAtLocal()
            rollbackStack.append(rollbackSetNewAccessLogAtLocal)
            util.log(.info, location, "Successfully set access-log at local", userId)
            
            // 4. ChallengeLog
            try setNewChallengeLogAtLocal()
            rollbackStack.append(rollbackSetNewChallengeLogAtLocal)
            util.log(.info, location, "Successfully set challenge-log at local", userId)
            
            rollbackStack.removeAll()
            return true
            
        } catch {
            util.log(.critical, location, "Unexpected error while processing storage new user data at local device", userId)
            return false
        }
    }
    
    // Server
    private func serverExecutor() async throws -> Bool {
        util.log(.info, location, "Proceed storage new-userdata at server", userId)
        do {
            // 1. User
            try await setNewUserProfileAtServer()
            rollbackStack.append(rollbackSetNewUserProfileAtServer)
            util.log(.info, location, "Successfully set profile at server", userId)
            
            // 2. Statistics
            try await setNewStatAtServer()
            rollbackStack.append(rollbackSetNewStatAtServer)
            util.log(.info, location, "Successfully set statistics at server", userId)
            
            // 3. AccessLog
            try await setNewAccessLogAtServer()
            rollbackStack.append(rollbackSetNewAccessLogAtServer)
            util.log(.info, location, "Successfully set access-log at server", userId)
            
            // 4. ChallengeLog
            try await setNewChallengeLogAtServer()
            rollbackStack.append(rollbackSetNewChallengeLogAtServer)
            util.log(.info, location, "Successfully set challenge-log at server", userId)
            
            // 5. Challenge
            try await setNewChallengeAtLocal()
            rollbackStack.append(rollbackSetNewChallengeAtLocal)
            util.log(.info, location, "Successfully set challenge-data from server", userId)
            
            rollbackStack.removeAll()
            return true
            
        } catch {
            util.log(.critical, location, "Unexpected error while processing storage new user data at server", userId)
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
// MARK: - Inspection
//===============================
extension SignupLoadingService{
    
    private func dataInspection(with profile: UserObject) {
        var log = """
            * ID: \(profile.user_id)
            * Email: \(profile.user_email)
            * NickName: \(profile.user_name)
            * Status: \(profile.user_status)
            * CreateAt: \(profile.user_created_at)
            * LoginAt: \(profile.user_login_at)
            * UpdateAt: \(profile.user_updated_at)
            """
        print(log)
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

