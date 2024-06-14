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
    @Published var signupUser: AuthSocialLoginResDTO?
    @Published var nonce: String?

    // private
    private let keychain = KeychainSwift()
    private let signupService = SignupService()
    private let loginService = LoginService()
    private lazy var loginLoadingService = LoginLoadingService()
    
    
    // MARK: - Login
    @MainActor
    func tryLogin() async -> Bool {
        // check: user data
        guard let loginUser = self.signupUser else { return false }
        
        // process: execute login process
        if await !loginLoadingService.executor(with: loginUser) {
            print("[AuthenticationViewModel] Failed to set UserDefault")
            return false
        }
        let user = self.loginLoadingService.userData
        
        // get: UserDefault
        getUserDefault(with: user.userId, and: user.nickName)
        return true
    }
    
    //MARK: - Signup
    @MainActor
    func trySignup(userName: String) async throws -> UserInfoDTO {
        // check: user data
        guard let signupUser = self.signupUser else { throw SignupError.invalidUser }
        
        // struct: add user nickName to signup data
        var finalUserInfo = try self.signupService.getAccountInfo(newUser: signupUser)
        finalUserInfo.updateNickName(with: userName)
        
        // set: new user data at Local & Server
        let signupService = SignupLoadingService(newUser: finalUserInfo)
        let signedUser = try await signupService.executor()
        
        // set: UserDefault
        setUserDefault(with: signedUser.userId, and: signedUser.nickName)
     
        return signedUser
    }
    
    // support
    private func getUserDefault(with userId: String, and name: String) {
        let userDefault = UserDefaultManager.loadWith(key: UserDefaultKey.user.rawValue) ??         UserDefaultManager.createWith(key: UserDefaultKey.user.rawValue)
        userDefault.identifier = userId
        userDefault.userName = name
        userDefault.save()
    }
    
    private func setUserDefault(with userId: String, and name: String) {
        let userDefault = UserDefaultManager.createWith(key: UserDefaultKey.user.rawValue)
        userDefault.identifier = userId
        userDefault.userName = name
        userDefault.save()
    }
}

// MARK: Social Login
extension AuthenticationViewModel {
    
    // Apple
    func requestNonceSignInApple() -> String {
        self.nonce = loginService.requestNonce()
        return loginService.reqeustNonceEncode(nonce: self.nonce!)
    }
    
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



