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
    // (구글)소셜로그인 기능
    private var googleAuthenticator: GoogleLoginService
    
    // FireBase 인증
    private var firebaseAuthenticator: AuthenticationManager
    
    // UserLogin 상태
    @Published var state: State
    
    // 인증정보 저장모델
    private var user: AuthenticatedUser
    
    
    //====================
    // Constructor
    //====================
    init(){
        if let currentUser = GIDSignIn.sharedInstance.currentUser{
            let authUser = AuthenticatedUser(user: currentUser)
            self.user = authUser
            self.state = .signedIn(authUser)
        } else {
            self.user = AuthenticatedUser()
            self.state = .signedOut
        }
        self.googleAuthenticator = GoogleLoginService()
        self.firebaseAuthenticator = AuthenticationManager()
    }
    
    
    //====================
    // Google Login
    //====================
    @MainActor
    func signInGoogle() async throws {
        
        // 로그인 & 인증
        let googleSignInUser = try await googleAuthenticator.signIn()
        let authUser = try await firebaseAuthenticator.signInWithGoogle(user: googleSignInUser)
        
        // 유저정보 저장
        self.user = authUser
        self.state = .signedIn(authUser)
        print("idToken: \(googleSignInUser.idToken)")
        print("accessToken: \(googleSignInUser.accessToken)")
        let keychain = KeychainSwift()
        keychain.set(googleSignInUser.idToken, forKey: "idToken")
        keychain.set(googleSignInUser.accessToken, forKey: "accessToken")
    }
    
    
    //====================
    // Authenticate
    //====================
    func logout() async throws {
        try firebaseAuthenticator.logout()
        self.user = AuthenticatedUser()
    }
}


//====================
// Extension
//====================
extension AuthenticationViewModel{
    enum State{
        case signedIn(AuthenticatedUser)
        case signedOut
    }
}
