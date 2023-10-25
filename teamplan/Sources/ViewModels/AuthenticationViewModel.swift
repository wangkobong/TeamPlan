//
//  AuthenticationViewModel.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/07/04.
//  Copyright © 2023 team1os. All rights reserved.
//
import Foundation
import GoogleSignIn
import KeychainSwift

final class AuthenticationViewModel: ObservableObject{
    
    //====================
    // Parameter
    //====================
    let loginService = LoginService()
    init(){}
    
    //====================
    // Google Login
    //====================
    @MainActor
    func signInGoogle(completion: @escaping (Result<AuthSocialLoginResDTO, Error>) -> Void) async {
        do {
            
            await loginService.loginGoogle { result in
                switch result {
                case .success(let user):
                    switch user.status {
                    case .exist:
                        print("########### Exist User ###########")
                    case .new:
                        print("########### New User ###########")
                    case .unknown:
                        print("########### UNKNOWN ###########")
                    }
                    
                    print(user.provider)
                    print(user.email)
                    print(user.status)
                    completion(.success(user))
                    print("idToken: \(user.idToken)")
                    print("accessToken: \(user.accessToken)")
                    let keychain = KeychainSwift()
                    keychain.set(user.idToken, forKey: "idToken")
                    keychain.set(user.accessToken, forKey: "accessToken")

                case .failure(let error):
                    // Login Fail
                    print("########### Error ###########")
                    print(error)
                    completion(.failure(error))
                }
            }
        }
    }
    
    
    /*====================
    // Authenticate
    //====================
    func logout() async throws {
        try firebaseAuthenticator.logout()
        self.user = AuthenticatedUser()
    }
    */
}


//====================
// Extension
//====================
extension AuthenticationViewModel{
    enum State{
        case signedIn
        case signedOut
    }
}
