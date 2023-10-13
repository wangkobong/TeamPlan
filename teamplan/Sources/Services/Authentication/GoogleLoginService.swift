//
//  SignInGoogleHelper.swift
//  teamplan
//
//  Created by sungyeon kim on 2023/06/01.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation
import GoogleSignIn
import GoogleSignInSwift

final class GoogleLoginService {
    
    //====================
    // Login
    //====================
    
    @MainActor
    func signIn() async throws -> GoogleSignInUser {
        guard let topVC = GoogleLoginHelper.shared.topViewController() else {
            throw URLError(.cannotFindHost)
        }
        
        // 소셜로그인 수행
        let gidSignInResult = try await GIDSignIn.sharedInstance.signIn(withPresenting: topVC)
        
        // 로그인정보 추출
        guard let idToken: String = gidSignInResult.user.idToken?.tokenString else {
            throw URLError(.badServerResponse)
        }
        let accessToken: String = gidSignInResult.user.accessToken.tokenString
        let name: String = gidSignInResult.user.profile?.name ?? "unknown"
        let email: String = gidSignInResult.user.profile?.email ?? "unknown"
        
        // 정보 모델화
        let tokens = GoogleSignInUser(idToken: idToken, accessToken: accessToken, name: name, email: email)
        return tokens
    }
}
