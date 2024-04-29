//
//  AuthGoogleServices.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/09/06.
//  Copyright © 2023 team1os. All rights reserved.
//
import UIKit
import Foundation
import GoogleSignIn
import FirebaseAuth
import KeychainSwift

final class AuthGoogleService {
    
    
    // MARK: - private properties
    private var keychain = KeychainSwift()
    
    @MainActor
    func login() async throws -> AuthSocialLoginResDTO {
        guard let topVC = GoogleLoginHelper.shared.topViewController() else {
            throw GoogleSocialLoginError.topViewControllerSearchFailure(serviceName: .googleLogin)
        }
        let loginResult = try await GIDSignIn.sharedInstance.signIn(withPresenting: topVC)
        let tokenInfo = try extractIdToken(with: loginResult.user)
        let authResult = try await registFirebaseAuth(with: loginResult, and: tokenInfo)
        return AuthSocialLoginResDTO(
            identifier: authResult.identifier,
            email: authResult.email,
            provider: .google,
            idToken: tokenInfo,
            accessToken: loginResult.user.accessToken.tokenString,
            status: authResult.status
        )
    }
    
    // TODO: Need Custom Exception
    private func extractIdToken(with user: GIDGoogleUser) throws -> String {
        guard let idToken = user.idToken?.tokenString else {
            throw GoogleSocialLoginError.topViewControllerSearchFailure(serviceName: .googleLogin)
        }
        return idToken
    }
    
    private func registFirebaseAuth(with loginResult: GIDSignInResult, and idToken: String) async throws -> FirebaseAuthRegistResultDTO {
        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: loginResult.user.accessToken.tokenString
        )
        do {
            let authResult = try await Auth.auth().signIn(with: credential)
            guard let loginInfo = authResult.additionalUserInfo,
                  let userEmail = authResult.user.email
            else {
                throw AppleSocialLoginError.signInFailed(serviceName: .appleLogin)
            }
            let identifier = authResult.user.uid
            return FirebaseAuthRegistResultDTO(identifier: identifier, email: userEmail, status: loginInfo.isNewUser ? .new : .exist)
        } catch {
            print("Firebase Auth sign-in error: \(error.localizedDescription)")
            throw error
        }
    }
    
    func logout() throws {
        try Auth.auth().signOut()
        keychain.delete("idToken")
        keychain.delete("accessToken")
        let userDefaultManager = UserDefaultManager.loadWith(key: "user")
        userDefaultManager?.identifier = ""
        userDefaultManager?.userName = ""
    }
}

// MARK: Exception

enum AuthGoogleError: LocalizedError {
    case UnexpectedTopViewControllerError
    
    var errorDescription: String?{
        switch self {
        case .UnexpectedTopViewControllerError:
            return "[Critical]AuthGoogle - Throw: There was an unexpected error while get TopView Controller"
        }
    }
}
