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
    func signInGoogle() async throws {
        
        await loginService.loginGoogle() { loginResult in
            switch loginResult {
            case .success(let user):
                
                // Login Success
                switch user.status{
                case .exist:
                    print("########### Exist User ###########")
                    print(user.provider)
                    print(user.email)
                    print(user.status)
                    print("##################################")
                    break
                case .new:
                    print("########### New User ###########")
                    print(user.provider)
                    print(user.email)
                    print(user.status)
                    print("##################################")
                    break
                case .unknown:
                    print("########### UNKNOWN ###########")
                    print(user.provider)
                    print(user.email)
                    print(user.status)
                    print("##################################")
                    break
                }
                break
            case .failure(let error):
                // Login Fail
                print("########### Error ###########")
                print(error)
                print("##################################")
                break
            }
        }
        /* UserInfo Save
        self.user = authUser
        self.state = .signedIn(authUser)
        print("idToken: \(googleSignInUser.idToken)")
        print("accessToken: \(googleSignInUser.accessToken)")
        let keychain = KeychainSwift()
        keychain.set(googleSignInUser.idToken, forKey: "idToken")
        keychain.set(googleSignInUser.accessToken, forKey: "accessToken")
         */
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
