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

final class AuthGoogleServices{
    
    private var keychain = KeychainSwift()
    
    @MainActor
    func login() async throws -> AuthSocialLoginResDTO {
        
        guard let topVC = GoogleLoginHelper.shared.topViewController() else {
            throw GoogleSocialLoginError.topViewControllerSearchFailure(serviceName: .googleLogin)
        }
        let loginResult = try await GIDSignIn.sharedInstance.signIn(withPresenting: topVC)
        let userType = try await firebaseAuth(loginResult: loginResult)
        let dto = AuthSocialLoginResDTO(loginResult: loginResult, userType: userType)
        return dto
    }
    
    // firebase authentication
    private func firebaseAuth(loginResult: GIDSignInResult) async throws -> UserType {
        let credential = GoogleAuthProvider.credential(
            withIDToken: loginResult.user.idToken!.tokenString,
            accessToken: loginResult.user.accessToken.tokenString
        )
        let authResult = try await Auth.auth().signIn(with: credential)
        return authResult.additionalUserInfo?.isNewUser == true ? UserType.new : UserType.exist
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
