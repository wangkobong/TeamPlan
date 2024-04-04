//
//  AuthDTO.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/09/06.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation
import FirebaseAuth
import GoogleSignIn


struct AuthSocialLoginResDTO {
    
    
    // MARK: - properties
    
    let email: String?
    let provider: Providers
    
    let idToken: String?
    let accessToken: String
    var status: UserType
    
    
    // MARK: - life cycle

    // MARK: Google
    
    init(loginResult: GIDSignInResult, userType: UserType) {
        self.provider = .google
        self.email = loginResult.user.profile?.email
        self.idToken = loginResult.user.idToken?.tokenString
        self.accessToken = loginResult.user.accessToken.tokenString
        self.status = userType
    }
    
    // MARK: Apple
    
    init(loginResult: User?, idToken: String, userType: UserType) {
        self.provider = .apple
        self.email = loginResult?.email
        self.idToken = idToken
        self.accessToken = ""
        self.status = userType
    }
    
}


// MARK: Enum

enum UserType: String{
    case new = "Normal: User User"
    case exist = "Normal: Exist User"
}
