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
                            self.signupUser = user
                        }
//                        DispatchQueue.main.async {
//                            self.loginLoadingService.getUser(authResult: user) { result in
//                                switch result {
//                                case .success(let loginUser):
//                                    print("loginUser: \(loginUser)")
//                                    let accountName = self.util.getAccountName(userEmail: loginUser.user_email)
//                                    let identifier = "\(accountName)_\(loginUser.user_social_type.rawValue)"
//                                    self.loginLoadingService.getStatistics(identifier: identifier) { result in
//                                        switch result {
//                                        case .success(let statistics):
//                                            print("statistics: \(statistics)")
////                                            self.loginLoadingService.getAccessLog(identifier: identifier) { result in
////                                                switch result {
////                                                case .success(let accessLog):
////                                                    print("accessLog: \(accessLog)")
////                                                case .failure(let error):
////                                                    print(error.localizedDescription)
////                                                }
////                                            }
//                                        case .failure(let error):
//                                            print(error.localizedDescription)
//                                        }
//                                    }
//                                case .failure(let error):
//                                    print(error.localizedDescription)
//                                }
//                            }
//
//                            
//                            
//                        }


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
    
    func trySignup(userName: String) async throws -> UserDTO {
        
        /*
        // 혼란을 드려 죄송합니다ㅠ
        // 과정을 요약드리자면
        // 1. getAccountInfo() 여기서는 social 로그인결과로 UserProfile 뼈대(UserSignupDTO)를 제작합니다
        // 2. 단, getAccountInfo() 에는 사용자입력을 받아 구성되는 'nickname' 정보가 누락되어 있습니다.
        // 3. View에서 nickname 값을 받아, UserProfile 뼈대(UserSignupDTO) 추가하는 작업이 필요합니다
        // 3-1. SignupService에 'setNickName' 함수가 구현되어 있습니다.
        // 4. NickName 까지 받아졌다면, 'SignupLoadingService' 로 UserProfile 뼈대(UserSignupDTO)를 넘겨주시면 됩니다
         
        // 아래 identifier은 이제 getAccountInfo 함수에 추가되어 아래과정은 불필요합니다!
        */
        
        guard let signupUser = self.signupUser else { throw SignupError.invalidUser }

        
        let accountInfo = try self.signupService.getAccountInfo(newUser: signupUser)
        let finalUserInfo = self.signupService.setNickName(newUser: accountInfo, nickName: userName)
        let signupService = SignupLoadingService(newUser: finalUserInfo)
        let signedUser = try await signupService.executor()
        return signedUser
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
    
    enum SignupError: Error {
        case invalidUser
        case invalidAccountInfo
        case signupFailed
    }
}
