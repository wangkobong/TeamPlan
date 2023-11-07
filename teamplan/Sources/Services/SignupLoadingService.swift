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
    
    //===============================
    // MARK: - Constructor
    //===============================
    init(newUser: UserSignupReqDTO){
        let signupDate = Date()
        self.newProfile = UserObject(newUser: newUser, signupDate: signupDate)
        self.newStat = StatisticsObject(identifier: newUser.identifier, signupDate: signupDate)
        self.newAccessLog = AccessLog(identifier: newUser.identifier, signupDate: signupDate)
        self.newChallengeLog = ChallengeLog(identifier: newUser.identifier, signupDate: signupDate)
    }
    
    //===============================
    // MARK: - Set User
    //===============================
    // : Firestore
    func setUserFS(result: @escaping(Result<Bool, Error>) -> Void) {
        userFS.setUser(reqUser: self.newProfile) { fsResult in
            switch fsResult {
    
            case .success(let docsId):
                self.newProfile.addDocsId(docsId: docsId)
                return result(.success(true))
                
            case .failure(let error):
                print(error)
                return result(.failure(error))
            }
        }
    }
    
    // : Coredata
    func setUserCD(result: @escaping(Result<Bool, Error>) -> Void) {
        userCD.setUser(reqUser: newProfile) { cdResult in
            self.handleServiceResult(cdResult, with: result)
        }
    }
    
    //===============================
    // MARK: - Set Statistics
    //===============================
    // : Firestore
    func setStatisticsFS(result: @escaping(Result<Bool, Error>) -> Void) {
        statFS.setStatistics(reqStat: self.newStat) { fsResult in
            self.handleServiceResult(fsResult, with: result)
        }
    }
    
    // : Coredata
    func setStatisticsCD(result: @escaping(Result<Bool, Error>) -> Void) {
        statCD.setStatistics(reqStat: self.newStat) { cdResult in
            self.handleServiceResult(cdResult, with: result)
        }
    }
    
    //===============================
    // MARK: - Set AccessLog
    //===============================
    // : Firestore
    func setAccessLogFS(result: @escaping(Result<Bool, Error>) -> Void) {
        aclogFS.setAccessLog(reqLog: self.newAccessLog) { fsResult in
            self.handleServiceResult(fsResult, with: result)
        }
    }
    
    // : Coredata
    func setAccessLogCD(result: @escaping(Result<Bool, Error>) -> Void) {
        aclogCD.setAccessLog(reqLog: self.newAccessLog) { cdResult in
            self.handleServiceResult(cdResult, with: result)
        }
    }
    
    //===============================
    // MARK: - Set ChallengeLog
    //===============================
    // : Firestore
    func setChallengeLogFS(result: @escaping(Result<Bool, Error>) -> Void) {
        chlglogFS.setChallengeLog(reqLog: self.newChallengeLog) { fsResult in
            self.handleServiceResult(fsResult, with: result)
        }
    }
    
    // ; Coredata
    func setChallengeLogCD(result: @escaping(Result<Bool, Error>) -> Void) {
        chlglogCD.setChallengeLog(reqLog: self.newChallengeLog) { cdResult in
            self.handleServiceResult(cdResult, with: result)
        }
    }
    
    //===============================
    // MARK: - Result Handler
    //===============================
    func handleServiceResult(_ serviceResult: Result<String, Error>,
                             with result: @escaping(Result<Bool, Error>) -> Void) {
        switch serviceResult {
        case .success(let message):
            print(message)
            result(.success(true))
        case .failure(let error):
            print(error)
            result(.failure(error))
        }
    }
}


