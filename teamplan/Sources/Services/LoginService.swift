//
//  LoginService.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/09/06.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation
import FirebaseAuth
import GoogleSignIn
import AuthenticationServices

final class LoginService{
    
    let google = AuthGoogleServices()
    let apple = AuthAppleServices()
    
    func loginGoole() async throws -> AuthSocialLoginResDTO {
        return try await google.login()
    }

    func loginApple(
        appleCredential: ASAuthorizationAppleIDCredential ,
        result: @escaping(Result<AuthSocialLoginResDTO, Error>) -> Void) async {
        
        await apple.login(appleCredential: appleCredential){ loginResult in
            switch loginResult {
            // Authentication Success: NewUser & Exist
            case .success(let userInfo):
                result(.success(userInfo))
                break
            // Authentication Failure: print error
            case .failure(let error):
                print(error)
                
                // TODO: case2. firebase authentication error
                // TODO: case3. Apple Social Login error
                
                break
            }
        }
    }
}

struct AuthSocialLoginResDTO{
    
    let email: String
    let provider: Providers
    let idToken: String
    let accessToken: String
    var status: UserType
    
    // Google
    init(loginResult: GIDSignInResult, userType: UserType){
        self.provider = .google
        self.email = loginResult.user.profile!.email
        self.idToken = loginResult.user.idToken!.tokenString
        self.accessToken = loginResult.user.accessToken.tokenString
        self.status = userType
    }
    
    // Apple
    init(loginResult: User, idToken: String, userType: UserType){
        self.provider = .apple
        self.email = loginResult.email!
        self.idToken = idToken
        self.accessToken = ""
        self.status = userType
    }
}

enum UserType: String{
    case new = "New User"
    case exist = "Exist User"
}
