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
    case login(userId: String)

    var path: String {
        switch self {
        case .login: return "/auth/login"

        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .login: return .post
        }
    }
    
    var parameters: Parameters? {
        switch self {
        case let .login(userId):
            return ["userId": userId]
        }
    }
}
