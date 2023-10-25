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

//============================
// MARK: DTO
//============================
struct AuthSocialLoginResDTO{
    
    // login info
    let email: String
    let provider: Providers
    
    // Token
    let idToken: String
    let accessToken: String
    
    // status
    var status: UserType
    
    // Constructor
    // Google Authentication: NewUser | ExistUser
    init(loginResult: GIDSignInResult, userType: UserType){
        self.provider = .google
        self.email = loginResult.user.profile!.email
        self.idToken = loginResult.user.idToken!.tokenString
        self.accessToken = loginResult.user.accessToken.tokenString
        self.status = userType
    }
    
    // Apple Authentication: NewUser | ExistUser
    init(loginResult: User, idToken: String, userType: UserType){
        self.provider = .apple
        self.email = loginResult.email!
        self.idToken = idToken
        self.accessToken = ""
        self.status = userType
    }
}

//============================
// MARK: Enum
//============================
enum UserType: String{
    case new = "Normal: User User"
    case exist = "Normal: Exist User"
    case unknown = "Caution: Unknown User"
}
