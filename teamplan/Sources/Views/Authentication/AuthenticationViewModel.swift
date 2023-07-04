//
//  AuthenticationViewModel.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/07/04.
//  Copyright © 2023 team1os. All rights reserved.
//
import Foundation

final class AuthenticationViewModel: ObservableObject{
    func signInGoogle() async throws {
        
        let helper = GoogleLoginService()
        let tokens = try await helper.signIn()
        try await AuthenticationManager.shared.signInWithGoogle(user: tokens)
    }
}
