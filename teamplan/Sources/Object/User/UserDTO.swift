//
//  UserDTO.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/08/24.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation


// MARK: After Auth

struct UserInfoDTO{
    
    
    // content
    
    let userId: String
    let email: String
    let nickNname: String
    let socialType: Providers
    let status: UserStatus
    let updatedAt: Date
    
    
    // constructor
    
    // Default
    init(){
        self.userId = "Unknown"
        self.email = "Unknown"
        self.nickNname = "Unknown"
        self.socialType = .unknown
        self.status = .unknown
        self.updatedAt = Date()
    }
    // Signup
    init(with userObject: UserObject){
        self.userId = userObject.user_id
        self.email = userObject.user_email
        self.nickNname = userObject.user_name
        self.socialType = Providers(rawValue: userObject.user_social_type) ?? .unknown
        self.status = UserStatus(rawValue: userObject.user_status) ?? .unknown
        self.updatedAt = userObject.user_updated_at
    }
}


// MARK: Signup

struct UserSignupDTO{
    
    
    // content
    
    let userId: String
    let email: String
    let provider: Providers
    var nickName: String
    
    
    // constructor
    
    init(with userId: String, and dto: AuthSocialLoginResDTO) {
        self.userId = userId
        self.email = dto.email ?? ""
        self.provider = dto.provider
        self.nickName = ""
    }
    
    // function
    
    mutating func updateNickName(with newVal: String){
        self.nickName = newVal
    }
}


// MARK: Update

struct UserUpdateDTO{
    
    
    // content
    
    let userId: String
    var newEmail: String?
    var newNickName: String?
    var newUpdateAt: Date?
    var newLoginAt: Date?
    
    
    // constructor
    
    init(userId: String, 
         newEmail: String? = nil,
         newNickName: String? = nil,
         newUpdateAt: Date? = nil,
         newLoginAt: Date? = nil) 
    {
        self.userId = userId
        self.newEmail = newEmail
        self.newNickName = newNickName
        self.newUpdateAt = newUpdateAt
        self.newLoginAt = newLoginAt
    }
}
