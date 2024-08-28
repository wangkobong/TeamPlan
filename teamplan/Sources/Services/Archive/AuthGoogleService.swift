//
//  AuthGoogleServices.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/09/06.
//  Copyright © 2023 team1os. All rights reserved.
/*
import UIKit
import Foundation
import GoogleSignIn
import FirebaseAuth
import KeychainSwift

final class AuthGoogleService {
    
    private var keychain = KeychainSwift()
    private let topViewManager = TopViewManager.shared
    
    // MARK: Main Func
    
    @MainActor
    func login() async throws -> AuthSocialLoginResDTO {
        guard let topVC = topViewManager.topViewController() else {
            await topViewManager.redirectToLoginView (
                title: "Warning!",
                message: "서비스의 동작이상이 감지되었습니다! 지속될 경우 재설치 해주세요"
            )
            throw NSError(
                domain: "TopViewManager",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "Failed to get top view controller"])
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
            await topViewManager.redirectToLoginView (
                title: "Warning!",
                message: "서비스의 동작이상이 감지되었습니다! 지속될 경우 재설치 해주세요"
            )
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
}
*/
