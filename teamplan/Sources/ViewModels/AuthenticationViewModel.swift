//
//  AuthenticationViewModel.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/07/04.
//  Copyright © 2023 team1os. All rights reserved.
//
import Foundation
import KeychainSwift
import AuthenticationServices

final class AuthenticationViewModel: ObservableObject {

    enum State {
        case signedIn
        case signedOut
    }

    enum SignupError: Error {
        case invalidUser
        case invalidAccountInfo
        case signupFailed
    }
    
    enum loginAction: Equatable {
        case loginGoogle
        case loginApple
    }
    
    
    // MARK: - published properties
    @Published var nickName: String = ""
    @Published var signupUser: AuthSocialLoginResDTO?
    @Published var nonce: String?

    
    // MARK: - private properties
    private let keychain = KeychainSwift()
    private lazy var loginLoadingService = LoginLoadingService()
    private let signupService = SignupService()
    
    private let loginService = LoginService(
        authGoogleService: AuthGoogleService(),
        authAppleService: AuthAppleService()
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
    
    func requestNonceSignInApple() {
        self.nonce = self.loginService.requestNonceSignInApple()
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
