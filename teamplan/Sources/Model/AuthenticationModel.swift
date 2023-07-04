//
//  AuthenticationModel.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/07/04.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation
import FirebaseAuth

//====================
// Google 소셜로그인
//====================

struct GoogleSignInUser{
    let idToken: String
    let accessToken: String
    let name: String?
    let email: String?
}

struct AuthDataResultModel {
    let uid: String
    let email: String?
    let photoUrl: String?
    
    init(user: User) {
        self.uid = user.uid
        self.email = user.email
        self.photoUrl = user.photoURL?.absoluteString
    }
}
