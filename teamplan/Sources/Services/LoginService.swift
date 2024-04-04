//
//  LoginService.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/09/06.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation
import GoogleSignIn
import FirebaseAuth
import AuthenticationServices

final class LoginService{

    private let google: AuthGoogleService
    private let apple: AuthAppleService

    // MARK: - life cycle
    init(authGoogleService: AuthGoogleService, authAppleService: AuthAppleService) {
        self.google = authGoogleService
        self.apple = authAppleService
    }
    
    // MARK: - method
    func loginGoogle() async throws -> AuthSocialLoginResDTO {
        return try await google.login()
    }
    
    func requestNonceSignInApple() -> String {
        return self.apple.randomNonce()
    }
}

// MARK: - AuthDTO
struct AuthSocialLoginResDTO {
    
    let email: String?
    let provider: Providers
    let idToken: String?
    let accessToken: String
    var status: UserType
    
    // Google
    init(loginResult: GIDSignInResult, userType: UserType){
        self.provider = .google
        self.email = loginResult.user.profile?.email
        self.idToken = loginResult.user.idToken?.tokenString
        self.accessToken = loginResult.user.accessToken.tokenString
        self.status = userType
    }
    
    // Apple
    init(loginResult: User?, idToken: String, userType: UserType){
        self.provider = .apple
        self.email = loginResult?.email
        self.idToken = idToken
        self.accessToken = ""
        self.status = userType
    }
}

enum UserType: String{
    case new = "New User"
    case exist = "Exist User"
}
