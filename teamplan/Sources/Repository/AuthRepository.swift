//
//  AuthRepository.swift
//  투두팡
//
//  Created by sungyeon on 1/9/25.
//  Copyright © 2025 team1os. All rights reserved.
//

import Foundation
import Alamofire

class AuthRepository {
    let networkService: NetworkService
    
    init(networkService: NetworkService = NetworkService()) {
        self.networkService = networkService
    }
    
    func trySignup(userSignupData: UserSignupData) async throws -> Bool {
        
        // 회원가입 API 호출
        let response: APIResponse<Bool?> = try await networkService.request(.signup(userId: userSignupData.userId,
                                                                                      name: userSignupData.name,
                                                                                      email: userSignupData.email,
                                                                                      socialType: userSignupData.socialType))
        
        return response.status == 200 && response.result == "SUCCESS"
    }

    func tryLogin(token: String, userId: String) async throws -> APIResponse<Bool?> {
        print("NetworkService instance:", networkService) // 객체 확인

        networkService.setToken(token)
        print("NetworkService instance2:", networkService) // 객체 확인

        // 로그인 API 호출
        let response: APIResponse<Bool?> = try await networkService.request(.login(userId: userId, idToken: token))
        
        // 응답 그대로 반환
        return response
    }
}
