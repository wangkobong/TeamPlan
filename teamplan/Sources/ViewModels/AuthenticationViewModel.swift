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
    
    
    // MARK: - published properties
    @Published var signupUser: AuthSocialLoginResDTO?
    @Published var nonce: String?

    
    // MARK: - private properties
    private let keychain = KeychainSwift()
    private let signupService = SignupService()
    private lazy var loginLoadingService = LoginLoadingService()
    
    private let loginService = LoginService(
        authGoogleService: AuthGoogleService(),
        authAppleService: AuthAppleService()
    )
    
    
    // MARK: - Login & Signup
    func tryLogin() async -> Bool {
        if let loginUser = self.signupUser {
            do {
                let user = try await self.loginLoadingService.executor(with: loginUser)
                let userDefaultManager = UserDefaultManager.loadWith(key: "user")
                userDefaultManager?.userName = user.nickName
                userDefaultManager?.identifier = user.userId
                return true
            } catch {
                print("Login error: \(error.localizedDescription)")
                return false
            }
        }
        
        return false
    }
    
    func trySignup(userName: String) async throws -> UserInfoDTO {
        
        guard let signupUser = self.signupUser else { throw SignupError.invalidUser }
        var finalUserInfo = try self.signupService.getAccountInfo(newUser: signupUser)
        finalUserInfo.updateNickName(with: userName)
        
        let signupService = SignupLoadingService(newUser: finalUserInfo)
        let signedUser = try await signupService.executor()
        
        let userDefaultManager = UserDefaultManager.loadWith(key: "user")
        userDefaultManager?.userName = signedUser.nickName
        userDefaultManager?.identifier = signedUser.userId
        
        return signedUser
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

        self.keychain.set(idToken, forKey: "idToken")
        self.keychain.set(dto.accessToken, forKey: "accessToken")
    }
}



