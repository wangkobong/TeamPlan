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
    
    // Step4-1. Update Statistics (ServiceTerm)
    
    // Step4-2. Update AccessLog
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
            case .failure(let error as UserServiceCDError) where error == .UserRetrievalByIdentifierFailed:
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
        userCD.setUser(userObject: user, result: result)
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
            case .failure(let error as StatCDError) where error == .StatRetrievalByIdentifierFailed:
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
    
    // Step1-2. Get from Firestore
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

