//
//  AuthGoogleServices.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/09/06.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation
import GoogleSignIn
import FirebaseAuth
import KeychainSwift

final class AuthGoogleServices{
    
    static let shared = AuthGoogleServices()
    private var keychain = KeychainSwift()
    init(){}
    
    //====================
    // MARK: Login
    //====================
    func login(result: @escaping(Result<AuthGoogleLoginResDTO, Error>) -> Void) async {
        
        do{
            guard let topVC = await Utilities.shared.topViewController() else {
                result(.failure(URLError(.cannotFindHost)))
                return
            }
            
            // Google Social Login
            let googleLoginResult = try await GIDSignIn.sharedInstance.signIn(withPresenting: topVC)
            let googleLoginUser = AuthGoogleLoginResDTO(loginResult: googleLoginResult)
            
            // Token Authentication
            do{
                let authUser = try await tokenAuth(candidate: googleLoginUser)
                return result(.success(authUser))
            } catch let authError {
                result(.failure(authError))
            }
            
        } catch let gidError {
            result(.failure(gidError))
        }
    }
    
    @discardableResult
    private func tokenAuth(candidate: AuthGoogleLoginResDTO) async throws -> AuthGoogleLoginResDTO {
        let credential = GoogleAuthProvider.credential(withIDToken: candidate.idToken, accessToken: candidate.accessToken)
        let authResult = try await Auth.auth().signIn(with: credential)
        
        return AuthGoogleLoginResDTO(authResult: authResult.user, loginResult: candidate)
    }
    
    
    //====================
    // MARK: Logout
    //====================
    func logout() throws {
        try Auth.auth().signOut()
        keychain.delete("idToken")
        keychain.delete("accessToken")
    }
}
