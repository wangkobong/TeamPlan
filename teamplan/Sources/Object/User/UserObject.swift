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
    
    //--------------------
    // content
    //--------------------
    let user_id: String
    let user_email: String
    let user_name: String
    let user_social_type: String
    let user_status: String
    let user_created_at: Date
    let user_login_at: Date
    let user_updated_at: Date
    
    //--------------------
    // constructor
    //--------------------
    // SignupService
    init(newUser: UserSignupDTO, signupDate: Date) {
        self.user_id = newUser.userId
        self.user_email = newUser.email
        self.user_name = newUser.nickName
        self.user_social_type = newUser.provider.rawValue
        self.user_status = UserStatus.active.rawValue
        self.user_created_at = signupDate
        self.user_login_at = signupDate
        self.user_updated_at = signupDate
    }
    
    // Coredata
    init?(userEntity: UserEntity) {
        guard let user_id = userEntity.user_id,
                let user_email = userEntity.user_email,
                let user_name = userEntity.user_name,
                let user_social_type = userEntity.user_social_type,
                let user_status = userEntity.user_status,
                let user_created_at = userEntity.user_created_at,
                let user_login_at = userEntity.user_login_at,
                let user_updated_at = userEntity.user_updated_at
        else {
            return nil
        }
        // Assigning values
        self.user_id = user_id
        self.user_email = user_email
        self.user_name = user_name
        self.user_social_type = user_social_type
        self.user_status = user_status
        self.user_created_at = user_created_at
        self.user_login_at = user_login_at
        self.user_updated_at = user_updated_at
    }
    
    // Firestore
    init?(userData: [String : Any]) {
        guard let user_id = userData["user_id"] as? String,
              let user_email = userData["user_email"] as? String,
              let user_name = userData["user_name"] as? String,
              let user_social_type = userData["user_social_type"] as? String,
              let user_status = userData["user_status"] as? String,
              let user_created_at = userData["user_created_at"] as? String,
              let user_login_at = userData["user_login_at"] as? String,
              let user_updated_at = userData["user_updated_at"] as? String
        else {
            return nil
        }
        // Assigning values
        self.user_id = user_id
        self.user_email = user_email
        self.user_name = user_name
        self.user_social_type = user_social_type
        self.user_status = user_status
        self.user_created_at = DateFormatter.standardFormatter.date(from: user_created_at)!
        self.user_login_at = DateFormatter.standardFormatter.date(from: user_login_at)!
        self.user_updated_at = DateFormatter.standardFormatter.date(from: user_updated_at)!
    }

    //--------------------
    // function
    //--------------------
    func toDictionary() -> [String: Any] {

        return [
            "user_id" : self.user_id,
            "user_email" : self.user_email,
            "user_name" : self.user_name,
            "user_social_type" : self.user_social_type,
            "user_status" : self.user_status,
            "user_created_at" : DateFormatter.standardFormatter.string(from: self.user_created_at),
            "user_login_at" : DateFormatter.standardFormatter.string(from: self.user_login_at),
            "user_updated_at" : DateFormatter.standardFormatter.string(from: self.user_updated_at)
        ]
    }
}

//============================
// MARK: Enum Type
//============================
enum UserStatus: String{
    case active = "Active"
    case dormant = "Dormant"
    case unknown = "Unknown"
}

enum Providers: String{
    case apple = "Apple"
    case google = "Google"
    case unknown = "Unknown Providers"
}
