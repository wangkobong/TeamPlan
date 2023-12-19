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
    
    //--------------------
    // content
    //--------------------
    let user_id: String
    let user_email: String
    let user_name: String
    let user_social_type: Providers
    let user_status: UserStatus
    let user_updated_at: Date
    
    //--------------------
    // constructor
    //--------------------
    // Signup
    init(with userObject: UserObject){
        self.user_id = userObject.user_id
        self.user_email = userObject.user_email
        self.user_name = userObject.user_name
        self.user_social_type = Providers(rawValue: userObject.user_social_type) ?? .unknown
        self.user_status = UserStatus(rawValue: userObject.user_status) ?? .unknown
        self.user_updated_at = userObject.user_updated_at
    }
    // Default
    init(){
        self.user_id = "Unknown"
        self.user_email = "Unknown"
        self.user_name = "Unknown"
        self.user_social_type = .unknown
        self.user_status = .unknown
        self.user_updated_at = Date()
    }
}

//============================
// MARK: Signup/SignupLoading
//============================
struct UserSignupDTO{
    
    //--------------------
    // content
    //--------------------
    let identifier: String
    let email: String
    let provider: Providers
    var nickName: String
    
    //--------------------
    // constructor
    //--------------------
    init(with userId: String, and dto: AuthSocialLoginResDTO) {
        self.identifier = userId
        self.email = dto.email
        self.provider = dto.provider
        self.nickName = ""
    }
    //--------------------
    // function
    //--------------------
    mutating func updateNickName(with newVal: String){
        self.nickName = newVal
    }
}
