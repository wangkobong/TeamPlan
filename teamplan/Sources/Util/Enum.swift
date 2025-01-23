//
//  Enum.swift
//  투두팡
//
//  Created by sungyeon on 1/23/25.
//  Copyright © 2025 team1os. All rights reserved.
//

import Foundation
import FirebaseAuth

enum socialLoginType: Int {
    case google = 0
    case apple = 1
}

enum LoginResult {
    case success(User)
    case needsSignup(UserSignupData)
}
