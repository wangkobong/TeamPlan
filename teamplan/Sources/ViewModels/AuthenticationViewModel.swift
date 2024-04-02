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
import FirebaseAuth
import AuthenticationServices

enum SignupError: Error {
    case invalidUser
    case invalidAccountInfo
    case signupFailed
}

final class AuthenticationViewModel: ObservableObject {
    
    enum State {
        case signedIn
        case signedOut
    }

    enum loginAction: Equatable {
        case loginGoogle
        case loginApple
    }
    
    // MARK: - published properties
    @Published var nickName: String = ""
    @Published var signupUser: AuthSocialLoginResDTO?
    @Published var rawNonce: String?
    @Published var hashedNonce: String?
    @Published var error: SignupError? // 에러타입 준수하는 어떤 것을 만들어서 값이 변경될 때마다 알럿 띄워줘야함. 지금은 아무거나(SignupError) 박아놓음
    @Published var appleLoginStatus: UserType?
    
    
    // MARK: - private properties
    private let keychain = KeychainSwift()
    private lazy var loginLoadingService = LoginLoadingService()
    private let signupService = SignupService()
    private let loginService = LoginService(
        authGoogleService: AuthGoogleServices(),
        authAppleService: AuthAppleServices()
    )
    
    
    // MARK: - method
    func signInGoogle() async throws -> AuthSocialLoginResDTO {
        do {
            let user = try await loginService.loginGoogle()
            
            switch user.status {
            case .exist:
                self.signupUser = user
            case .new:
                self.signupUser = user
            }

            guard let idToken = user.idToken else {
                throw SignupError.invalidAccountInfo
            }
            self.keychain.set(idToken, forKey: "idToken")
            self.keychain.set(user.accessToken, forKey: "accessToken")
            
            return user
        } catch {
            throw error
        }
    }
    
    func signInApple(providerID: String = "apple.com", idToken: String) {
        let credential: OAuthCredential = {
            return OAuthProvider.credential(withProviderID: providerID, idToken: idToken, rawNonce: self.rawNonce)
        }()
        self.loginService.loginApple(credential: credential, idToken: idToken) { [weak self] loginResult in
            DispatchQueue.main.async {
                switch loginResult {
                case .success(let response):
                    self?.appleLoginStatus = response.status
                case .failure(let error):
                    self?.error = error
                }
            }
        }
    }
    
    func requestRandomNonce() {
        self.rawNonce = self.loginService.requestRandomNonce()
    }
 
    func tryLogin() async -> Bool {
        if let loginUser = self.signupUser {
            do {
                let user = try await self.loginLoadingService.executor(with: loginUser)
                let userDefaultManager = UserDefaultManager.loadWith(key: "user")
                userDefaultManager?.userName = user.nickName
                userDefaultManager?.identifier = user.userId
                return true
            } catch {
                print("Login error: \(error.localizedDescription)")
                return false
            }
        }
        
        return false
    }
    
    func trySignup(userName: String) async throws -> UserInfoDTO {
        
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

        
        var finalUserInfo = try self.signupService.getAccountInfo(newUser: signupUser)
        finalUserInfo.updateNickName(with: userName)
        let signupService = SignupLoadingService(newUser: finalUserInfo)
        let signedUser = try await signupService.executor()
        let userDefaultManager = UserDefaultManager.loadWith(key: "user")
        userDefaultManager?.userName = signedUser.nickName
        userDefaultManager?.identifier = signedUser.userId
        return signedUser
    }
}
