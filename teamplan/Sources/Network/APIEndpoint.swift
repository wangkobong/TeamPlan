//
//  APIEndpoint.swift
//  투두팡
//
//  Created by sungyeon on 1/9/25.
//  Copyright © 2025 team1os. All rights reserved.
//

import Foundation
import Alamofire

enum APIEndpoint {
    case signup(userId: String, name: String, email: String, socialType: SocialLoginType)
    case login(userId: String, idToken: String)
    case getHomeInfo(userId: String)

    var path: String {
        switch self {
        case .signup: return "/auth/signup"
        case .login: return "/auth/login"
        case .getHomeInfo: return "/home/get"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .signup: return .post
        case .login: return .post
        case .getHomeInfo: return .post
        }
    }
    
    var parameters: Parameters? {
        switch self {
        case let .signup(userId, name, email, socialType):
            return ["userId": userId, "name": name, "email": email, "socialType": socialType.rawValue]
        case let .login(userId, idToken):
            return ["userId": userId, "idToken": idToken]
        case let .getHomeInfo(userId):
            return ["userId": userId]
        }
    }
}
