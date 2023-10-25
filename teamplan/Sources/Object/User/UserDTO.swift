//
//  UserDTO.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/08/24.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation

//============================
// MARK: After Auth
//============================
struct UserDTO{
    // id
    let user_id: String
    
    // content
    let user_email: String
    let user_name: String
    
    // status:
    let user_social_type: Providers
    let user_status: UserStatus
    
    // maintenance:
    let user_updated_at: Date
    
    init(userObject: UserObject){
        self.user_id = userObject.user_id
        self.user_email = userObject.user_email
        self.user_name = userObject.user_name
        self.user_social_type = Providers(rawValue: userObject.user_social_type) ?? .unknown
        self.user_status = UserStatus(rawValue: userObject.user_status) ?? .unknown
        self.user_updated_at = userObject.user_updated_at
    }
}

//============================
// MARK: Signup/SignupLoading
//============================
/// Request DTO : View -> Service
struct UserSignupReqDTO{
    // info
    let identifier: String
    let email: String
    let provider: Providers
    var nickName: String
    
    // Constructor
    init(
        identifier: String,
        email: String,
        provider: Providers
    ) {
        self.identifier = identifier
        self.email = email
        self.provider = provider
        self.nickName = ""
    }
    
    // func
    mutating func addNickName(nickName: String){
        self.nickName = nickName
    }
}

struct UserSignupResDTO{
    // info
    let accountName: String
    let provider: Providers
    
    // Constructor
    init(accountName: String, provider: Providers){
        self.accountName = accountName
        self.provider = provider
    }
}

//============================
// MARK: Home
//============================
struct UserHomeResDTO{
    // id
    let user_id: String
    
    // content
    let user_name: String
    
    init(userObject: UserObject){
        self.user_id = userObject.user_id
        self.user_name = userObject.user_name
    }
}
