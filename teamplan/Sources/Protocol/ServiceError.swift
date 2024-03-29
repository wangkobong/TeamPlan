//
//  ErrorProtocol.swift
//  teamplan
//
//  Created by 크로스벨 on 3/24/24.
//  Copyright © 2024 team1os. All rights reserved.
//

protocol ServiceErrorProtocol: Error {
    var serviceName: ServiceType { get }
    var errorLocation: ErrorLocation { get }
    var errorDescription: String { get }
}

enum ErrorLocation: String {
    case coredata = "Coredata"
    case firestore = "Firestore"
    case google = "GoogleSocialLogin"
    case signup = "Signup"
    case login = "LoginLoading"
}

enum ServiceType: String {
    case coreValue = "CoreValue"
    case user = "User"
    case stat = "Statistics"
    case challenge = "Challenge"
    case project = "Project"
    case todo = "todo"
    case log = "AccessLog"
    case googleLogin = "GoogleSocialLogin"
    case signup = "SignupLoading"
    case login = "LoginLoading"
}

// MARK: - Coredata
enum CoredataError: ServiceErrorProtocol {
    case fetchFailure(serviceName: ServiceType)
    case convertFailure(serviceName: ServiceType)
    
    var serviceName: ServiceType {
        switch self {
        case .fetchFailure(let serviceName), .convertFailure(let serviceName):
            return serviceName
        }
    }
    
    var errorLocation: ErrorLocation {
        return .coredata
    }
    
    var errorDescription: String {
        return getErrorDescription(for: self)
    }
}

// MARK: - Firestore
enum FirestoreError: ServiceErrorProtocol {
    case fetchFailure(serviceName: ServiceType)
    case convertFailure(serviceName: ServiceType)
    
    var serviceName: ServiceType {
        switch self {
        case .fetchFailure(let serviceName), .convertFailure(let serviceName):
            return serviceName
        }
    }
    
    var errorLocation: ErrorLocation {
        return .firestore
    }
    
    var errorDescription: String {
        return getErrorDescription(for: self)
    }
}

// MARK: - Google Social Login
enum GoogleSocialLoginError: ServiceErrorProtocol {
    case topViewControllerSearchFailure(serviceName: ServiceType)
    
    var serviceName: ServiceType {
        switch self {
        case .topViewControllerSearchFailure(let serviceName):
            return serviceName
        }
    }
    var errorLocation: ErrorLocation {
        return .google
    }
    var errorDescription: String {
        return getErrorDescription(for: self)
    }
}

// MARK: - Signup Loading
enum SignupLoadingError: ServiceErrorProtocol {
    case signupFailure(serviceName: ServiceType)
    
    var serviceName: ServiceType {
        switch self {
        case .signupFailure(let serviceName):
            return serviceName
        }
    }
    var errorLocation: ErrorLocation {
        return .signup
    }
    var errorDescription: String {
        return getErrorDescription(for: self)
    }
}

// MARK: - Login Loading
enum LoginLoadingError: ServiceErrorProtocol {
    case syncLocalWithServerFailure(serviceName: ServiceType)
    case syncServerWithLocalFailure(serviceName: ServiceType)
    case getAccessLogFailure(serviceName: ServiceType)
    
    var serviceName: ServiceType {
        switch self {
        case .syncLocalWithServerFailure(let serviceName):
            return serviceName
        case .syncServerWithLocalFailure(let serviceName):
            return serviceName
        case .getAccessLogFailure(let serviceName):
            return serviceName
        }
    }
    var errorLocation: ErrorLocation {
        return .signup
    }
    var errorDescription: String {
        return getErrorDescription(for: self)
    }
}

// MARK: - Description
func getErrorDescription(for error: ServiceErrorProtocol) -> String {
    let baseMessage = "[\(error.errorLocation.rawValue)] Failed "
    switch error {
        
    case let error as CoredataError:
        switch error {
        case .fetchFailure(let serviceName):
            return baseMessage + "to fetch '\(serviceName.rawValue)' entity."
        case .convertFailure(let serviceName):
            return baseMessage + "to convert '\(serviceName.rawValue)' entity to object."
        }
        
    case let error as FirestoreError:
        switch error {
        case .fetchFailure(let serviceName):
            return baseMessage + "to fetch '\(serviceName.rawValue)' document."
        case .convertFailure(let serviceName):
            return baseMessage + "to convert '\(serviceName.rawValue)' document to object."
        }
        
    case let error as GoogleSocialLoginError:
        switch error {
        case .topViewControllerSearchFailure(let serviceName):
            return baseMessage + "to search 'topViewController' at '\(serviceName.rawValue)'"
        }
        
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
