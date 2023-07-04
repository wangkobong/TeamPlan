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

final class SignInGoogleHelper {
    
    @MainActor
    func signIn() async throws -> GoogleSignInResultModel {
        guard let topVC = Utilities.shared.topViewController() else {
            throw URLError(.cannotFindHost)
        }
        
        let gidSignInResult = try await GIDSignIn.sharedInstance.signIn(withPresenting: topVC)
        
        guard let idToken: String = gidSignInResult.user.idToken?.tokenString else {
            throw URLError(.badServerResponse)
        }
        let accessToken: String = gidSignInResult.user.accessToken.tokenString
        let name: String = gidSignInResult.user.profile?.name ?? "unknown"
        let email: String = gidSignInResult.user.profile?.email ?? "unknown"
        let tokens = GoogleSignInResultModel(idToken: idToken, accessToken: accessToken, name: name, email: email)
        return tokens
    }
}
