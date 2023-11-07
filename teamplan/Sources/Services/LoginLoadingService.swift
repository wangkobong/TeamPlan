//
//  LoginLoadingService.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/10/25.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation

final class LoginLoadingService{
    
    let util = Utilities()
    let userCD = UserServicesCoredata()
    let userFS = UserServicesFirestore()
    let statCD = StatisticsServicesCoredata()
    let statFS = StatisticsServicesFirestore()
    let acclogCD = AccessLogServicesCoredata()
    let acclogFS = AccessLogServicesFirestore()
    
    var accLog: AccessLog? = nil
    
    //==============================
    // MARK: Core Function
    //==============================
    // Step1. Get User
    func getUser(authResult: AuthSocialLoginResDTO,
                 result: @escaping(Result<UserDTO, Error>) -> Void) {
        
        // extract Identifer from LoginInfo
        getIdentifier(authResult: authResult) { [weak self] response in
            switch response {
                
                // Search Coredata
            case .success(let identifier):
                self?.fetchUser(identifier: identifier, result: result)
                
                // Exception Handling : Invalid Email Format
            case .failure(let error):
                return result(.failure(error))
            }
        }
    }
    
    // Step2. Get Statistics
    func getStatistics(identifier: String,
                       result: @escaping(Result<StatisticsDTO, Error>) -> Void) {
        
        // Retrive Statistics by Identifier
        self.fetchStatistics(identifier: identifier) { response in
            switch response {
                
            // Successfully get Statistics
            case .success(let statInfo):
                return result(.success(statInfo))
                
            // Exception Handling : UnExpected error while fetching Statistics from Coredata or Firestore
            case .failure(let error):
                return result(.failure(error))
            }
        }
    }
    
    // Step3. Get AccessLog
    func getAccessLog(identifier: String,
                      result: @escaping(Result<Bool, Error>) -> Void) {
        
        // Retrive AccessLog by Identifier
        self.fetchAccessLog(identifier: identifier) { response in
            switch response {
                
            // Successfully get AccessLog
            case .success(let log):
                self.accLog = log
                return result(.success(true))
                
            // Exception Handling : UnExpected error while get AccessLog from Coredata or Firestore
            case .failure(let error):
                return result(.failure(error))
            }
        }
    }
    
    // Step4-1. Update Statistics (ServiceTerm)
    func updateStatistics(identifier: String, stat: StatisticsDTO, loginDate: Date,
                          result: @escaping(Result<Bool, Error>) -> Void) {
        
        // Check AccessLog
        guard let lastLoginDate = self.accLog?.log_access.last else {
            return result(.failure(LoginLoadingServiceError.EmptyAccessLog))
        }
        // User has login record of that day
        if util.calcTime(currentTime: loginDate, lastTime: lastLoginDate) {
            return result(.success(false))
        }
        
        // Update Statistics
        var updatedStat = stat
        updatedStat.updateServiceTerm(updatedTerm: stat.stat_term + 1)
        
        // Update Coredata & Firestore
        self.updateStatisticsStore(identifier: identifier, updatedStat: updatedStat) { response in
            switch response {
                
            // Successfully Update Statistics
            case .success(_):
                return result(.success(true))
                
            // Exception Handling : UnExpected error while Update Statistics from Coredata or Firestore
            case .failure(let error):
                return result(.failure(error))
            }
        }
    }
    
    // Step4-2. Update AccessLog
    func updateAccessLog(identifier: String, serviceTerm: Int, loginDate: Date,
                         result: @escaping(Result<Bool, Error>) -> Void) {
        
        // Check AccessLog
        guard var accessLog = self.accLog else {
            return result(.failure(LoginLoadingServiceError.EmptyAccessLog))
        }
        
        // Manage AccessLog size
        if accessLog.log_access.count > 365 {
            accessLog.log_access.removeAll()
        }
        
        // Update AccessLog
        accessLog.log_access.append(loginDate)
        
        // Update Coredata & Firestore
        self.updateAccessLogStore(identifier: identifier, serviceTerm: serviceTerm, updatedAcclog: accessLog) { response in
            switch response {
                
            // Successfully Update Statistics
            case .success(_):
                return result(.success(true))
                
            // Exception Handling : UnExpected error while Update Statistics from Coredata or Firestore
            case .failure(let error):
                return result(.failure(error))
            }
        }
    }
}

//==============================
// MARK: Get User
//==============================
extension LoginLoadingService{
    
    // Step1. Identifier
    func getIdentifier(authResult: AuthSocialLoginResDTO,
                       result: @escaping(Result<String, Error>) -> Void) {
        util.getIdentifier(authRes: authResult, result: result)
    }
    
    // Step2. Get User From Coredata or Firestore
    func fetchUser(identifier: String,
                   result: @escaping(Result<UserDTO, Error>) -> Void) {
        
        self.fetchUserFromCoredata(identifier: identifier) { [weak self] response in
            switch response {
                
                // Successfully get UserInfo from CoreData
            case .success(let userInfo):
                return result(.success(UserDTO(userObject: userInfo)))
                
                // No userInfo at CoreData => Jump to Firestore
            case .failure(let error as UserErrorCD) where error == .UserRetrievalByIdentifierFailed:
                self?.fetchUserFromFirestore(identifier: identifier, result: result)
                
                // ExceptionHandling : Internal Error (Coredata)
            case .failure(let error):
                return result(.failure(error))
            }
        }
    }
    
    // Step3-1. Get from Coredata
    private func fetchUserFromCoredata(identifier: String,
                                       result: @escaping(Result<UserObject, Error>) -> Void) {
        userCD.getUser(identifier: identifier, result: result)
    }
    
    // Step3-2. (Option) Get from Firestore
    private func fetchUserFromFirestore(identifier: String,
                                        result: @escaping(Result<UserDTO, Error>) -> Void) {
        
        userFS.getUser(identifier: identifier) { [weak self] fsResponse in
            switch fsResponse {
                
                // Successgully get UserInfo from Firestore
            case .success(let userInfo):
                
                // Set userInfo to Coredata
                self?.storeUserToCoredata(user: userInfo) { cdResponse in
                    switch cdResponse {
                    case .success(let msg):
                        print(msg)
                        return result(.success(UserDTO(userObject: userInfo)))
                        
                        // ExceptionHandling : Internal Error (Coredata)
                    case .failure(let error):
                        result(.failure(error))
                    }
                }
                // No userInfo at Firestore
                // 'UserFSError.IdentiferDocsGetError' case = newUser
            case .failure(let error):
                return result(.failure(error))
            }
        }
    }
    
    // Step1-3. (Option) Store to Coredata
    private func storeUserToCoredata(user: UserObject,
                                     result: @escaping(Result<String, Error>) -> Void) {
        userCD.setUser(reqUser: user, result: result)
    }
}

//==============================
// MARK: Get Statistics
//==============================
extension LoginLoadingService{
    
    // Step1. Fetch Stattistics From Coredata or Firestore
    private func fetchStatistics(identifier: String,
                                 result: @escaping(Result<StatisticsDTO, Error>) -> Void) {
        self.fetchStatFromCoredata(identifier: identifier) { response in
            switch response {
                
            // Successfully get StatInfo from CoreData
            case .success(let statInfo):
                return result(.success(StatisticsDTO(statObject: statInfo)))
                
            // No StatInfo at CoreData => Jump to Firestore
            case .failure(let error as StaticErrorCD) where error == .StatRetrievalByIdentifierFailed:
                self.fetchStatFromFirestore(identifier: identifier, result: result)
                
            // ExceptionHandling : Internal Error (Coredata)
            case .failure(let error):
                return result(.failure(error))
            }
        }
    }
    
    // Step1-1. Get from Coredata
    private func fetchStatFromCoredata(identifier: String,
                                       result: @escaping(Result<StatisticsObject, Error>) -> Void) {
        statCD.getStatistics(identifier: identifier, result: result)
    }
    
    // Step1-2. (Option) Get from Firestore
    private func fetchStatFromFirestore(identifier: String,
                                        result: @escaping(Result<StatisticsDTO, Error>) -> Void) {
        
        statFS.getStatistics(identifier: identifier) { [weak self] fsResponse in
            switch fsResponse {
                
            // Successgully get UserInfo from Firestore
            case .success(let statInfo):
                
                // Set StatInfo to Coredata
                self?.storeStatToCoredata(statInfo: statInfo) { cdResponse in
                    switch cdResponse {
                    case .success(let msg):
                        print(msg)
                        return result(.success(StatisticsDTO(statObject: statInfo)))
                        
                    // ExceptionHandling : Internal Error (Coredata)
                    case .failure(let error):
                        return result(.failure(error))
                    }
                }
                
            // ExceptionHandling : Failed to Search (Firestore)
            case .failure(let error):
                return result(.failure(error))
            }
        }
    }
    
    // Step1-3. (Option) Store to Coredata
    private func storeStatToCoredata(statInfo: StatisticsObject,
                                     result: @escaping(Result<String, Error>) -> Void) {
        statCD.setStatistics(reqStat: statInfo, result: result)
    }
}

//==============================
// MARK: Get Access Log
//==============================
extension LoginLoadingService{
    
    // Step1. Fetch AccessLog from Coredata or Firestore
    func fetchAccessLog(identifier: String,
                      result: @escaping(Result<AccessLog, Error>) -> Void) {
        
        self.fetchAcclogFromCoredata(identifier: identifier) { response in
            switch response {
                
            // Successfully get AccessLog from CoreData
            case .success(let acclog):
                return result(.success(acclog))
               
            // No AccessLog at CoreData => Jump to Firestore
            case .failure(let error as AccessLogErrorCD) where error == .AccLogRetrievalByIdentifierFailed:
                self.fetchAcclogFromFirestore(identifier: identifier, result: result)
                
            // ExceptionHandling : Internal Error (Coredata)
            case .failure(let error):
                return result(.failure(error))
            }
        }
    }
    
    // Step1-1. Get from Coredata
    private func fetchAcclogFromCoredata(identifier: String,
                                         result: @escaping(Result<AccessLog, Error>) -> Void) {
        acclogCD.getAccessLog(identifier: identifier, result: result)
    }
    
    // Step1-2. (Option) Get from Firestore
    private func fetchAcclogFromFirestore(identifier: String,
                                          result: @escaping(Result<AccessLog, Error>) -> Void) {
        
        // Successgully get AccessLog from Firestore
        acclogFS.getAccessLog(identifier: identifier) { fsResponse in
            switch fsResponse {
                
            case .success(let log):
                
                // Set AccessLog to Coredata
                self.storeLogToCoredata(log: log) { cdResponse in
                    switch cdResponse {
                    case .success(let msg):
                        print(msg)
                        return result(.success(log))
                        
                    // ExceptionHandling : Internal Error (Coredata)
                    case .failure(let error):
                        return result(.failure(error))
                    }
                }
                
            // ExceptionHandling : Failed to Search (Firestore)
            case .failure(let error):
                return result(.failure(error))
            }
        }
    }
    
    // Step1-3. (Option) Store to Coredata
    private func storeLogToCoredata(log: AccessLog,
                                    result: @escaping(Result<String, Error>) -> Void) {
        acclogCD.setAccessLog(reqLog: log, result: result)
    }
}

//==============================
// MARK: Update Statistics
//==============================
extension LoginLoadingService{
    
    func updateStatisticsStore(identifier: String, updatedStat: StatisticsDTO,
                           result: @escaping(Result<String, Error>) -> Void) {
            
        // Step1. Update Coredata
        self.updateStatToCoredata(identifier: identifier, updatedStat: updatedStat) { cdResponse in
            switch cdResponse {
            case .success(let msg):
                print(msg)
                
                // Step2. (Option) Update Firestore
                // If the Coredata update was successful and the stat_term is a multiple of 7, then update Firestore
                if updatedStat.stat_term % 7 == 0 {
                    self.updateStatToFirestore(identifier: identifier, updatedStat: updatedStat, result: result)
                } else {
                    result(.success("Successfully updated Coredata only."))
                }
                
                // ExceptionHandling : Failed to Update (Coredata)
            case .failure(let error):
                result(.failure(error))
            }
        }
    }
    
    private func updateStatToCoredata(identifier: String, updatedStat: StatisticsDTO,
                                      result: @escaping(Result<String, Error>) -> Void) {
        
        statCD.updateStatistics(identifier: identifier, updatedStat: updatedStat, result: result)
    }
    
    private func updateStatToFirestore(identifier: String, updatedStat: StatisticsDTO,
                                       result: @escaping(Result<String, Error>) -> Void) {
        statFS.updateStatistics(identifier: identifier, updatedStat: updatedStat, result: result)
    }
}

//==============================
// MARK: Update AccessLog
//==============================
extension LoginLoadingService{
    
    func updateAccessLogStore(identifier: String, serviceTerm: Int, updatedAcclog: AccessLog,
                         result: @escaping(Result<String, Error>) -> Void) {
        
        // Step1. Update Coredata
        self.updateAcclogToCoredata(identifier: identifier, updatedAcclog: updatedAcclog) { cdResponse in
            switch cdResponse {
            case .success(let msg):
                print(msg)
                
                // Step2. Update Firestore
                // If the Coredata update was successful and the stat_term is a multiple of 7, then update Firestore
                if serviceTerm % 7 == 0 {
                    self.updateAcclogToFirestore(identifier: identifier, updatedAcclog: updatedAcclog, result: result)
                } else {
                    result(.success("Successfully updated Coredata only."))
                }
                
            // ExceptionHandling : Failed to Update (Coredata)
            case .failure(let error):
                return result(.failure(error))
            }
        }
    }
    
    private func updateAcclogToCoredata(identifier: String, updatedAcclog: AccessLog,
                                        result: @escaping(Result<String, Error>) -> Void) {
        acclogCD.updateAccessLog(identifier: identifier, updatedAcclog: updatedAcclog, result: result)
    }
    
    private func updateAcclogToFirestore(identifier: String, updatedAcclog: AccessLog,
                                         result: @escaping(Result<String, Error>) -> Void) {
        acclogFS.updateAccessLog(identifier: identifier, updatedLog: updatedAcclog, result: result)
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
