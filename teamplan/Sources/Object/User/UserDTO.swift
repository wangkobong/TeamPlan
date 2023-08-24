//
//  UserDTO.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/08/24.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation

//============================
// MARK: Signup - Local
//============================
/// Request DTO : View -> Service
struct UserSignupLocalReqDTO{
    // content
    let name: String
    let socialType: String
    let email: String
    
    // Constructor
    init(
        name: String,
        socialType: String,
        email: String
    ) {
        self.name = name
        self.socialType = socialType
        self.email = email
    }
}


//============================
// MARK: Signup - Server
//============================
/// Request DTO : Service -> Firestore
struct UserSignupServerReqDTO{
    // id
    let user_id: String
    
    // content
    let user_email: String
    var user_name: String
    
    // status
    let user_social_type: String
    var user_status: UserType
    
    // maintenance
    let user_created_at: Date
    var user_login_at: Date
    var user_updated_at: Date
    
    // Constructor
    init(reqUser: UserSignupLocalReqDTO, identifier: String) {
        let currentDate = Date()
        
        self.user_id = identifier
        self.user_email = reqUser.email
        self.user_name = reqUser.name
        self.user_social_type = reqUser.socialType
        self.user_status = .active
        self.user_created_at = currentDate
        self.user_login_at = currentDate
        self.user_updated_at = currentDate
    }
    
    // Firestore Extension
    func toDictionary() -> [String: Any] {
            return [
                "user_id": self.user_id,
                "user_email": self.user_email,
                "user_name": self.user_name,
                "user_social_type": self.user_social_type,
                "user_status": self.user_status.rawValue,
                "user_created_at": self.user_created_at,
                "user_login_at": self.user_login_at,
                "user_updated_at": self.user_updated_at
            ]
        }
}
