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
    
    func logoutUser() async -> Bool {
        do {
            await clearUserDataTasks()
            try Auth.auth().signOut()
            return true
        } catch {
            print("[LoginService] Failed to signOut at FirebaseAuth: \(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - Withdraw

    func withdrawUser() async -> Bool {
        do {
            await clearUserDataTasks()
            try await removeUserAtAuth()
            return true
        } catch {
            print("[LoginService] Failed to withdraw user: \(error.localizedDescription)")
            return false
        }
    }
}

// MARK: - Util

extension LoginService {
    
    private func clearUserDataTasks() async {
        async let isUserDefaultClear: () = clearUserDefault()
        async let isKeyChainDelete: () = deleteFromKeyChain()
        
        await _ = [isUserDefaultClear, isKeyChainDelete]
    }
    
    private func clearUserDefault() async {
        if let userDefault = UserDefaultManager.loadWith() {
            userDefault.clear()
            print("[LoginService] Successfully cleared userDefault")
        } else {
            print("[LoginService] No userDefault to clear")
        }
    }
    
    private func deleteFromKeyChain() async {
        keyChain.delete(KeyChainArgs.id.rawValue)
        keyChain.delete(KeyChainArgs.access.rawValue)
    }
    
    private func removeUserAtAuth() async throws {
        guard let user = Auth.auth().currentUser else {
            print("[MypageService] No user to remove at FirebaseAuth")
            return
        }
        do {
            try await user.delete()
            print("[MypageService] Successfully removed user at FirebaseAuth")
        } catch {
            print("[MypageService] Failed to remove user at FirebaseAuth: \(error.localizedDescription)")
            throw error
        }
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
