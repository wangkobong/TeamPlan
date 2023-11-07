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
    let util = Utilities()
    lazy var loginLoadingService = LoginLoadingService()
    
    @Published var nickName: String = ""
    @Published var signupUser: AuthSocialLoginResDTO?
    let signupService = SignupService()
    init(){}
    
    //====================
    // Google Login
    //====================
    @MainActor
    func signInGoogle(completion: @escaping (Result<AuthSocialLoginResDTO, Error>) -> Void) async {
        do {
            
            await loginService.loginGoogle { [self] result in
                switch result {
                    
                case .success(let user):
                    switch user.status {
                    case .exist:
                        print("########### Exist User ###########")
                        DispatchQueue.main.async {
                            self.loginLoadingService.getUser(authResult: user) { result in
                                switch result {
                                case .success(let loginUser):
                                    print("loginUser: \(loginUser)")
                                    let accountName = self.util.getAccountName(userEmail: loginUser.user_email)
                                    let identifier = "\(accountName)_\(loginUser.user_social_type.rawValue)"
                                    self.loginLoadingService.getStatistics(identifier: identifier) { result in
                                        switch result {
                                        case .success(let statistics):
                                            print("statistics: \(statistics)")
//                                            self.loginLoadingService.getAccessLog(identifier: identifier) { result in
//                                                switch result {
//                                                case .success(let accessLog):
//                                                    print("accessLog: \(accessLog)")
//                                                case .failure(let error):
//                                                    print(error.localizedDescription)
//                                                }
//                                            }
                                        case .failure(let error):
                                            print(error.localizedDescription)
                                        }
                                    }
                                case .failure(let error):
                                    print(error.localizedDescription)
                                }
                            }

                            
                            
                        }


                    case .new:
                        print("########### New User ###########")
                        DispatchQueue.main.async {
                            self.signupUser = user
                        }
                    case .unknown:
                        print("########### UNKNOWN ###########")
                    }
                    completion(.success(user))
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
    
    func trySignup(userName: String) {
        guard let signupUser = self.signupUser else { return }
        self.signupService.getAccountInfo(newUser: signupUser) { getAccountInfoResult in
            switch getAccountInfoResult {
            case .success(let userInfo):
                let identifier = "\(userInfo.accountName)_\(userInfo.provider.rawValue)"
                let singUpUser = UserSignupReqDTO(identifier: identifier,
                                                  email: signupUser.email,
                                                  provider: signupUser.provider)

                let signupService = SignupLoadingService(newUser: singUpUser)
            case .failure(let error):
                print(error.localizedDescription)
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
