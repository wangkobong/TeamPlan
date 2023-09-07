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
// MARK: Google Login
//============================

struct AuthGoogleLoginResDTO{
    
    // id
    let uid: String
    
    // login info
    let email: String
    
    // Token
    let idToken: String
    let accessToken: String
    
    // status
    let isAuth: Bool
    
    // Constructor
    // Login
    init(loginResult: GIDSignInResult){
        self.uid = ""
        self.email = loginResult.user.profile?.email ?? "Unkown Email"
        self.idToken = loginResult.user.idToken?.tokenString ?? "Unknown idToken"
        self.accessToken = loginResult.user.accessToken.tokenString
        self.isAuth = false
    }
    
    // Authentication
    init(authResult: User, loginResult: AuthGoogleLoginResDTO){
        self.uid = authResult.uid
        self.email = authResult.email ?? "Unkown Email"
        self.idToken = loginResult.idToken
        self.accessToken = loginResult.accessToken
        self.isAuth = true
    }
}
