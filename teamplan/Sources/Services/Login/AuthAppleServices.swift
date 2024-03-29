//
//  AuthAppleServices.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/10/13.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation
import FirebaseAuth
import AuthenticationServices

final class AuthAppleServices{
    
    private var nonceGen: String?
    
    init() {
        self.nonceGen = AppleLoginSupport.shared.randomNonceString()
    }
    
    // MARK: Login
    func login(appleCredential: ASAuthorizationAppleIDCredential ,
               completion: @escaping(Result<AuthSocialLoginResDTO, Error>) -> Void) async {
        
        // Get Random nonce for credential
        guard let nonce = nonceGen else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Nonce is missing"])))
            return
        }
        
        // Check for Apple's ID Token in the auth result
        guard let appleIDToken = appleCredential.identityToken else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to fetch identity token"])))
            return
        }
        
        // Convert token to string
        guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to serialize token string from data"])))
            return
        }
        
        // Create Firebase credential using token string and nonce
        let credential = OAuthProvider.credential(withProviderID: "apple.com", idToken: idTokenString, rawNonce: nonce)
        
        do{
            let authResult = try await Auth.auth().signIn(with: credential)
            let userType = authResult.additionalUserInfo?.isNewUser == true ? UserType.new : UserType.exist
            
            completion(.success(AuthSocialLoginResDTO(loginResult: authResult.user, idToken: idTokenString, userType: userType)))
        } catch {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown error occurred"])))
        }
    }
}
