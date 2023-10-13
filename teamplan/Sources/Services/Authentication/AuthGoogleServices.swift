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
    func login(result: @escaping(Result<AuthSocialLoginResDTO, Error>) -> Void) async {
        
        do{
            // Google Social Setting
            guard let topVC = await GoogleLoginHelper.shared.topViewController() else {
                throw URLError(.cannotFindHost)
            }
            
            // Google Social Login
            let googleLoginResult = try await GIDSignIn.sharedInstance.signIn(withPresenting: topVC)
            
            // Firebase Authorization
            let authResult = try await firebaseAuth(loginResult: googleLoginResult)
            return result(.success(AuthSocialLoginResDTO(loginResult: googleLoginResult, status: authResult)))
            
            // Excpetion
        } catch let GIDError as GIDSignInError {
            result(.failure(GIDError))
        } catch let FBError as FirebaseAuth.AuthErrorCode {
            result(.failure(FBError))
        } catch {
            result(.failure(FirebaseAuth.AuthErrorCode.internalError as! Error))
        }
    }
    
    // Token Authorization & NewUser Check
    private func firebaseAuth(loginResult: GIDSignInResult) async throws -> UserStatus {
        
        let credential = GoogleAuthProvider.credential(
            withIDToken: loginResult.user.idToken!.tokenString,
            accessToken: loginResult.user.accessToken.tokenString
        )
        do{
            let authResult = try await Auth.auth().signIn(with: credential)
            return authResult.additionalUserInfo?.isNewUser == true ? UserStatus.new : UserStatus.exist
        } catch {
            print(FirebaseAuth.AuthErrorCode.internalError as! Error)
            return UserStatus.unknown
        }
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
