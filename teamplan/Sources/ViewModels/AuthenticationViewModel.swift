//
//  AuthenticationViewModel.swift
//  teamplan
//
//  Created by 송하민 on 3/24/24.
//  Copyright © 2024 team1os. All rights reserved.
//

import Foundation
import KeychainSwift
import AuthenticationServices

final class AuthenticationViewModel: ObservableObject {

    enum State {
        case signedIn
        case signedOut
    }

    enum SignupError: Error {
        case invalidUser
        case invalidAccountInfo
        case signupFailed
    }
    
    enum loginAction: Equatable {
        case loginGoogle
        case loginApple
    }
    
    // MARK: - properties
    
    // published
    @Published var nonce: String?
    @Published var signupUser: AuthSocialLoginResDTO?
    @Published var loginUser: UserInfoDTO?
    @Published var isReSignupNeeded: Bool = false
    
    // private
    private let keychain = KeychainSwift()
    private let signupService = SignupService()
    private let loginService = LoginService()
    
    // MARK: - Login
    
    @MainActor
    func tryLogin() async -> Bool {
        // check: user data
        guard let loginUser = self.signupUser else {
            print("[AuthViewModel] Failed to get loginData")
            return false
        }
        let loginLoadingService = await LoginLoadingService.createInstance(with: loginUser)
        
        // process: execute login process
        if await !loginLoadingService.executor() {
            if !loginLoadingService.isValidUser {
                self.isReSignupNeeded = true
                print("[AuthViewModel] Unstable user detected, redirect to signup")
            }
            return false
        }
        let user = loginLoadingService.userData
        
        if await getUserDefault(with: user.userId, and: user.nickName) {
            print("[AuthViewModel] Successfully proceed login process")
            return true
        } else {
            print("[AuthViewModel] Failed to proceed login process")
            return false
        }
    }
    
    //MARK: - Signup
    
    @MainActor
    func trySignup(userName: String) async -> Bool {
        // check: user data
        guard let signupUser = self.signupUser else {
            print("[AuthViewModel] Failed to get loginData")
            return false
        }
        
        // struct: add user nickName to signup data
        var finalUserInfo = self.signupService.getAccountInfo(newUser: signupUser)
        finalUserInfo.updateNickName(with: userName)
        
        // set: new user data at Local & Server
        let signupService = SignupLoadingService(newUser: finalUserInfo)
        if await !signupService.executor() {
            print("[AuthViewModel] Failed to proceed signup process")
            return false
        }
        print("[AuthViewModel] Successfully proceed signup")
        let registedUser = signupService.userData
        
        // set: UserDefault
        if await setUserDefault(with: registedUser.userId, and: registedUser.nickName) {
            self.loginUser = registedUser
            
            print("[AuthViewModel] Successfully set UserDefault")
            return true
        } else {
            print("[AuthViewModel] Failed to proceed login process")
            return false
        }
    }
    
    //MARK: UserDefault
    
    private func getUserDefault(with userId: String, and name: String) async -> Bool {
        if let userDefault = UserDefaultManager.loadWith() {
            userDefault.identifier = userId
            userDefault.userName = name
            return userDefault.save()
        } else if let userDefault = UserDefaultManager.createWith() {
            userDefault.identifier = userId
            userDefault.userName = name
            return userDefault.save()
        } else {
            return false
        }
    }
    
    private func setUserDefault(with userId: String, and name: String) async -> Bool {
        if let userDefault = UserDefaultManager.createWith() {
            userDefault.identifier = userId
            userDefault.userName = name
            return userDefault.save()
        } else {
            return false
        }
    }
}

// MARK: Social Login
extension AuthenticationViewModel {
    
    // Apple
    @MainActor
    func requestNonceSignInApple() -> String {
        let candidateNonce = loginService.requestNonce()
        let encodedNonce = loginService.reqeustNonceEncode(nonce: candidateNonce)
        self.nonce = candidateNonce
        return encodedNonce
    }
    
    @MainActor
    func signInApple(with authResult: ASAuthorization) async throws -> AuthSocialLoginResDTO {
        guard let nonce = self.nonce else { throw SignupError.signupFailed }
        let userInfo = try await loginService.loginApple(appleAuthResult: authResult, nonce: nonce)
        try registKeyChain(with: userInfo)
        return userInfo
    }
    
    // Google
    func signInGoogle() async throws -> AuthSocialLoginResDTO {
        let userInfo = try await loginService.loginGoogle()
        try registKeyChain(with: userInfo)
        return userInfo
    }
    
    // Support
    private func registKeyChain(with dto: AuthSocialLoginResDTO) throws {
        self.signupUser = dto
        let idToken = dto.idToken
        let accessToken = dto.accessToken

        self.keychain.set(idToken, forKey: KeyChainArgs.id.rawValue)
        self.keychain.set(accessToken, forKey: KeyChainArgs.access.rawValue)
    }
}



