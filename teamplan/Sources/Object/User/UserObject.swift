//
//  UserObject.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/08/22.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation

//============================
// MARK: Entity
//============================
struct UserObject{
    // id
    var user_id: String
    var user_fb_id: String
    
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
    
    
    // For: Set Coredata
    init(newUser: UserSignupServerReqDTO, docsId: String) {
        self.user_id = newUser.user_id
        self.user_fb_id = docsId
        self.user_email = newUser.user_email
        self.user_name = newUser.user_name
        self.user_social_type = newUser.user_social_type
        self.user_status = UserType.active
        self.user_created_at = newUser.user_created_at
        self.user_login_at = newUser.user_login_at
        self.user_updated_at = newUser.user_updated_at
    }
}

//============================
// MARK: Extension
//============================
enum UserType: String{
    case active = "Activated"
    case dormant = "Dormanted"
}
