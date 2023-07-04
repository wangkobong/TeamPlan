//
//  AuthenticationManager.swift
//  teamplan
//
//  Created by sungyeon kim on 2023/06/01.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation
import FirebaseAuth

enum AuthProviderOption: String {
    case email = "password"
    case google = "google.com"
    case apple = "apple.com"
}

final class AuthenticationManager {
    
    static let shared = AuthenticationManager()
    init() { }
    
    //==============================
    // 인증완료 유저정보 추출
    //==============================
    func getAuthenticatedUser() throws -> AuthenticatedUser {
        guard let user = Auth.auth().currentUser else {
            throw URLError(.badServerResponse)
        }
        
        return AuthenticatedUser(user: user)
    }

    //==============================
    // 로그인방식 추출
    //==============================
    func getProvider() throws -> [AuthProviderOption] {
        guard let providerData = Auth.auth().currentUser?.providerData else {
            throw URLError(.badServerResponse)
        }
        
        var providers: [AuthProviderOption] = []
        for provider in providerData {
            if let option = AuthProviderOption(rawValue: provider.providerID) {
                providers.append(option)
            } else {
                assertionFailure("Provider option not found: \(provider.providerID)")
            }
        }
        
        return providers
    }
    
    //==============================
    // 로그아웃
    //==============================
    func logout() throws {
        do{
            try Auth.auth().signOut()
        } catch let signOutError as NSError {
            print("Error signing out: %@", signOutError)
          }
    }
}

// MARK: - SIGN IN SSO
extension AuthenticationManager {
    
    //==============================
    // GoogleToken 추출
    //==============================
    @discardableResult
    func signInWithGoogle(user: GoogleSignInUser) async throws -> AuthenticatedUser {
        let credential = GoogleAuthProvider.credential(withIDToken: user.idToken, accessToken: user.accessToken)
        return try await firebaseAuthentication(credential: credential)
    }

    
    //==============================
    // FireBase 인증
    //==============================
    func firebaseAuthentication(credential: AuthCredential) async throws -> AuthenticatedUser {
        let authResult = try await Auth.auth().signIn(with: credential)
        return AuthenticatedUser(user: authResult.user)
    }
}
