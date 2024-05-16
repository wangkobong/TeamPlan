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
    
    private var keychain = KeychainSwift()
    
    // MARK: Main Func
    
    @MainActor
    func login() async throws -> AuthSocialLoginResDTO {
        guard let topVC = GoogleLoginHelper.shared.topViewController() else {
            throw GoogleSocialLoginError.topViewControllerSearchFailed(serviceName: .google)
        }
        do {
            // FirebaseAuth Authentication
            let loginResult = try await GIDSignIn.sharedInstance.signIn(withPresenting: topVC)
            let tokenInfo = try extractIdToken(with: loginResult.user)
            let authResult = try await registFirebaseAuth(with: loginResult, and: tokenInfo)
            
            // Auth Result
            return AuthSocialLoginResDTO(
                identifier: authResult.identifier,
                email: authResult.email,
                provider: .google,
                idToken: tokenInfo,
                accessToken: loginResult.user.accessToken.tokenString,
                status: authResult.status
            )
            // Excpetion Handling
        } catch {
            print("[GoogleLogin] Failed to SignIn with GoogleSocialLogin: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: Support Func
    private func extractIdToken(with user: GIDGoogleUser) throws -> String {
        guard let idToken = user.idToken?.tokenString else {
            throw GoogleSocialLoginError.tokenExtractionFalied(serviceName: .google)
        }
        return idToken
    }
    
    private func registFirebaseAuth(with loginResult: GIDSignInResult, and idToken: String) async throws -> FirebaseAuthRegistResultDTO {
        // Create Credential
        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: loginResult.user.accessToken.tokenString
        )
        do {
            // Regist FirebaseAuth
            let authResult = try await Auth.auth().signIn(with: credential)
            guard let loginInfo = authResult.additionalUserInfo,
                  let userEmail = authResult.user.email
            else {
                throw AppleSocialLoginError.invalidFirebaseAuthUserInfo(serviceName: .google)
            }
            
            // Authentication Result
            let identifier = authResult.user.uid
            return FirebaseAuthRegistResultDTO(
                identifier: identifier,
                email: userEmail,
                status: loginInfo.isNewUser ? .new : .exist
            )
        } catch {
            throw GoogleSocialLoginError.firebaseAuthRegistrationFailed(
                serviceName: .google, firebaseError: error.localizedDescription
            )
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
