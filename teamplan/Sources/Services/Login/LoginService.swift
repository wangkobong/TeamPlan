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
import KeychainSwift
import AuthenticationServices

final class LoginService{

    private let google: AuthGoogleService
    private let apple: AuthAppleService
    private var keyChain = KeychainSwift()

    // MARK: - life cycle
    init() {
        self.google = AuthGoogleService()
        self.apple = AuthAppleService()
    }
    
    // MARK: - Login
    
    // Google Login
    func loginGoogle() async throws -> AuthSocialLoginResDTO {
        return try await google.login()
    }
    
    // Apple Login
    func loginApple(appleAuthResult: ASAuthorization, nonce: String) async throws -> AuthSocialLoginResDTO {
        return try await apple.login(loginResult: appleAuthResult, nonce: nonce)
    }
    
    func requestNonce() -> String {
        return self.apple.randomNonce()
    }
    
    func reqeustNonceEncode(nonce: String) -> String {
        return self.apple.sha256(nonce)
    }
    
    // Local Login
    
    
    // MARK: - Logout
    
    func logoutUser() {
        do {
            try Auth.auth().signOut()   // logout from firebaseAuth
            try resetUserDefault()      // reset userDefault
            deleteFromKeyChain()        // reset keyChain
        } catch let error as NSError {
            print("Logout Error : \(error.localizedDescription)")
        }
    }
    
    private func deleteFromKeyChain() {
        keyChain.delete(KeyChainArgs.id.rawValue)
        keyChain.delete(KeyChainArgs.access.rawValue)
    }
    
    private func resetUserDefault() throws {
        guard let userDefault = UserDefaultManager.loadWith() else {
            //TODO: Custom Error
            throw LoginLoadingError.getAccessLogFailure(serviceName: .login)
        }
        userDefault.clear()
    }
}

// MARK: - AuthDTO
struct AuthSocialLoginResDTO {
    
    let identifier: String
    let email: String
    let provider: Providers
    let idToken: String
    let accessToken: String
    var status: UserType
    
    init(identifier: String, email: String, provider: Providers, idToken: String, accessToken: String, status: UserType) {
        self.identifier = identifier
        self.email = email
        self.provider = provider
        self.idToken = idToken
        self.accessToken = accessToken
        self.status = status
    }
}

// MARK: FirebaseAuthDTO
struct FirebaseAuthRegistResultDTO {
    let identifier: String
    let email: String
    let status: UserType
    
    init(identifier: String, email: String, status: UserType) {
        self.identifier = identifier
        self.email = email
        self.status = status
    }
}

enum UserType {
    case new
    case exist
}

enum KeyChainArgs: String {
    case id = "idToken"
    case access = "accessToken"
}
