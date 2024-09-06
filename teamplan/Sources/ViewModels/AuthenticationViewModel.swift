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
    @Published var isReSignupNeeded: Bool = false
    
    // private
    private let signupService = SignupService()
    private let voltManager = VoltManager.shared
    
    //MARK: - Signup
    
    func classifyFunction() -> Bool {
        if let userId = voltManager.getUserId(),
           let userName = voltManager.getUserName() {
            return true
        } else {
            return false
        }
    }
    
    //MARK: - Signup
    
    func trySignup(userName: String) async -> Bool {

        // set: new user data at Local & volt
        guard signupService.executor(with: userName) else {
            print("[AuthViewModel] Failed to proceed signup process")
            await changeStatus()
            return false
        }
        print("[AuthViewModel] Successfully proceed signup")
        return true
    }
    
    // MARK: - Login
    
    func tryLogin(userId: String) async -> Bool {
        
        // check: userId
        guard let userId = voltManager.getUserId() else {
            print("[AuthViewModel] Failed to get userData from volt")
            await changeStatus()
            return false
        }
        let loginService = LoginService.initService(with: userId)
        
        if await loginService.executor() {
            print("[AuthViewModel] Login Process Success")
            return true
        } else {
            print("[AuthViewModel] Login Process Failed")
            await changeStatus()
            return false
        }
    }
    
    @MainActor
    private func changeStatus() {
        isReSignupNeeded = true
    }
}
