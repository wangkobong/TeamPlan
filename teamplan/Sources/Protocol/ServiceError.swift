//
//  ErrorProtocol.swift
//  teamplan
//
//  Created by 크로스벨 on 3/24/24.
//  Copyright © 2024 team1os. All rights reserved.
//

import Foundation

enum ServiceType: String {
    // Storage
    case cd = "Coredata"
    case fs = "Firestore"
    
    // Authentication
    case signup = "SignupLoading"
    case login = "LoginLoading"
    case google = "GoogleSocialLogin"
    case apple = "AppleSocialLogin"
    
    // Synchronize
    case serverToLocal = "LocalSynchronizer"
    case localToServer = "ServerSynchronizer"
    
    //Service
    case home = "Home"
    case challenge = "Challenge"
    case project = "Project"
    case mypage = "MyPage"
}

enum DataType: String {
    case null = "Null"
    
    case coreValue = "CoreValue"
    case user = "User"
    case stat = "Statistics"
    case challenge = "Challenge"
    case project = "Project"
    case todo = "todo"
    case aclog = "AccessLog"
    case exlog = "ExtendLog"
}

protocol ServiceErrorProtocol: Error {
    var errorService: ServiceType { get }
    var errorData: DataType { get }
    var errorMessage: String { get }
}

extension ServiceErrorProtocol {
    var errorDescription: String {
        "[\(errorService.rawValue)-\(errorData.rawValue)] Failed to \(errorMessage)"
    }
}

// MARK: - Coredata
enum CoredataError: ServiceErrorProtocol {
    case fetchFailure(serviceName: ServiceType, dataType: DataType)
    case convertFailure(serviceName: ServiceType, dataType: DataType)
    case searchFailure(serviceName: ServiceType, dataType: DataType)
    
    var errorService: ServiceType {
            switch self {
            case .fetchFailure(let service, _), 
                    .convertFailure(let service, _),
                    .searchFailure(serviceName: let service, _):
                return service
            }
        }
        
    var errorData: DataType {
        switch self {
        case .fetchFailure(_, let data), 
                .convertFailure(_, let data),
                .searchFailure(_, let data):
            return data
        }
    }
    
    var errorMessage: String {
        switch self {
        case .fetchFailure:
            return "to fetch '\(errorData.rawValue)' entity from Coredata."
        case .convertFailure:
            return "to convert '\(errorData.rawValue)' entity to object."
        case .searchFailure:
            return "to search '\(errorData.rawValue)' entity at Coredata"
        }
    }
}

// MARK: - Firestore
enum FirestoreError: ServiceErrorProtocol {
    case fetchFailure(serviceName: ServiceType, dataType: DataType)
    case convertFailure(serviceName: ServiceType, dataType: DataType)
    
    var errorService: ServiceType {
            switch self {
            case .fetchFailure(let service, _), .convertFailure(let service, _):
                return service
            }
        }
        
    var errorData: DataType {
        switch self {
        case .fetchFailure(_, let data), .convertFailure(_, let data):
            return data
        }
    }
    
    var errorMessage: String {
        switch self {
        case .fetchFailure:
            return "to fetch '\(errorData.rawValue)' entity from Firestore."
        case .convertFailure:
            return "to convert '\(errorData.rawValue)' entity to object."
        }
    }
}

// MARK: - Apple Login
enum AppleSocialLoginError: ServiceErrorProtocol {
    case tokenExtractionFalied(serviceName: ServiceType)
    case invalidFirebaseAuthUserInfo(serviceName: ServiceType)
    case firebaseAuthRegistrationFailed(serviceName: ServiceType, firebaseError: String)
    
    var errorService: ServiceType {
        switch self {
        case .tokenExtractionFalied(let serviceName), .invalidFirebaseAuthUserInfo(let serviceName), .firebaseAuthRegistrationFailed(let serviceName, _):
            return serviceName
        }
    }
    
    var errorData: DataType {
        return .null
    }
    
    var errorMessage: String {
        switch self {
        case .tokenExtractionFalied:
            return "to extract TokenData from Apple Credential"
        case .invalidFirebaseAuthUserInfo:
            return "to get valid UserData from FirebaseAuth"
        case .firebaseAuthRegistrationFailed(_, let error):
            return "to regist UserData at FirebaseAuth: \(error)"
        }
    }
}

// MARK: - Google Login
enum GoogleSocialLoginError: ServiceErrorProtocol {
    case topViewControllerSearchFailed(serviceName: ServiceType)
    case tokenExtractionFalied(serviceName: ServiceType)
    case invalidFirebaseAuthUserInfo(serviceName: ServiceType)
    case firebaseAuthRegistrationFailed(serviceName: ServiceType, firebaseError: String)
    
    var errorService: ServiceType {
        switch self {
        case .topViewControllerSearchFailed(let serviceName),
                .tokenExtractionFalied(let serviceName),
                .invalidFirebaseAuthUserInfo(let serviceName),
                .firebaseAuthRegistrationFailed(let serviceName, _):
            return serviceName
        }
    }
    
    var errorData: DataType {
        return .null
    }
    var errorMessage: String {
        switch self {
        case .topViewControllerSearchFailed:
            return "to search TopViewController"
        case .tokenExtractionFalied:
            return "to extract TokenData from GID Credential"
        case .invalidFirebaseAuthUserInfo:
            return "to get valid UserData from FirebaseAuth"
        case .firebaseAuthRegistrationFailed(_, let error):
            return "to regist UserData at FirebaseAuth: \(error)"
        }
    }
}

// MARK: - Signup Loading
enum SignupLoadingError: ServiceErrorProtocol {
    case signupFailure(serviceName: ServiceType)
    
    var errorService: ServiceType {
        switch self {
        case .signupFailure(let serviceName):
            return serviceName
        }
    }
    var errorData: DataType {
        return .null
    }
    var errorMessage: String {
        return getErrorDescription(for: self)
    }
}

// MARK: - Login Loading
enum LoginLoadingError: ServiceErrorProtocol {
    case syncLocalWithServerFailure(serviceName: ServiceType)
    case syncServerWithLocalFailure(serviceName: ServiceType)
    case getAccessLogFailure(serviceName: ServiceType)
    
    var errorService: ServiceType {
        switch self {
        case .syncLocalWithServerFailure(let serviceName):
            return serviceName
        case .syncServerWithLocalFailure(let serviceName):
            return serviceName
        case .getAccessLogFailure(let serviceName):
            return serviceName
        }
    }
    var errorData: DataType {
        return .null
    }
    var errorMessage: String {
        return getErrorDescription(for: self)
    }
}

// MARK: - Description
func getErrorDescription(for error: ServiceErrorProtocol) -> String {
    let baseMessage = "[\(error.errorData.rawValue)] Failed "
    switch error {
    case let error as SignupLoadingError:
        switch error {
        case .signupFailure(let serviceName):
            return baseMessage + "to regist new user at '\(serviceName.rawValue)'"
        }
        
    case let error as LoginLoadingError:
        switch error {
        case .syncLocalWithServerFailure(let serviceName):
            return baseMessage + "to synchronize local with server at '\(serviceName.rawValue)'"
        case .syncServerWithLocalFailure(let serviceName):
            return baseMessage + "to synchronize server with local at '\(serviceName.rawValue)'"
        case .getAccessLogFailure(let serviceName):
            return baseMessage + "get AccessLog at '\(serviceName.rawValue)'"
        }
        
    default:
        return "Unknown error occurred."
    }
}
