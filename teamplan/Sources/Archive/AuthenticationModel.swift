//
//  AuthenticationModel.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/07/04.
//  Copyright © 2023 team1os. All rights reserved.
/*

import Foundation
import FirebaseAuth
import GoogleSignIn

//====================
// Google 소셜로그인
//====================
struct GoogleSignInUser{
    let idToken: String
    let accessToken: String
    let name: String?
    let email: String?
}


//====================
// FireBase 인증
//====================
struct AuthenticatedUser{
    let uid: String
    let email: String?
    let photoUrl: String?
    
    // Default Null User
    init(){
        self.uid = "No UID Data"
        self.email = "No Email Data"
        self.photoUrl = "No URL Data"
    }
    
    // Google User
    init(user: GIDGoogleUser){
        self.uid = user.userID.unsafelyUnwrapped
        self.email = user.profile?.email
        self.photoUrl = user.profile?.imageURL(withDimension: 320)?.absoluteString
    }
    
    // Firebase User
    init(user: User) {
        self.uid = user.uid
        self.email = user.email
        self.photoUrl = user.photoURL?.absoluteString
    }
}

*/
