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
    
    func login(credential: OAuthCredential, idToken: String, completion: @escaping (Result<AuthSocialLoginResDTO, SignupError>) -> Void) {
        Auth.auth().signIn(with: credential) { (authResult, error) in
            if let error = error {
                completion(.failure(.invalidUser))
                return
            }
            
            guard let user = authResult?.user else {
                completion(.success(.init(loginResult: nil, idToken: idToken, userType: .new)))
                return
            }
            
            completion(.success(.init(loginResult: user, idToken: idToken, userType: .exist)))
        }
    }
}
