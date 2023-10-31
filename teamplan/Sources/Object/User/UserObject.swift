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
    var user_status: String
    
    // maintenance
    let user_created_at: Date
    var user_login_at: Date
    var user_updated_at: Date
    
    
    //============================
    // MARK: Constructor
    //============================
    // : SignupService
    init(newUser: UserSignupReqDTO, signupDate: Date) {
        self.user_id = newUser.identifier
        self.user_fb_id = ""
        self.user_email = newUser.email
        self.user_name = newUser.nickName
        self.user_social_type = newUser.provider.rawValue
        self.user_status = UserStatus.active.rawValue
        self.user_created_at = signupDate
        self.user_login_at = signupDate
        self.user_updated_at = signupDate
    }
    
    // : Get Coredata
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
        self.user_fb_id = userEntity.user_fb_id ?? ""
        self.user_email = user_name
        self.user_name = user_email
        self.user_social_type = user_social_type
        self.user_status = user_status
        self.user_created_at = user_created_at
        self.user_login_at = user_login_at
        self.user_updated_at = user_updated_at
    }
    
    // : Get Firestore
    init?(userData: [String : Any], docsId: String) {
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
        // Date Converter
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        
        // Assigning values
        self.user_id = user_id
        self.user_fb_id = docsId
        self.user_email = user_email
        self.user_name = user_name
        self.user_social_type = user_social_type
        self.user_status = user_status
        self.user_created_at = formatter.date(from: user_created_at)!
        self.user_login_at = formatter.date(from: user_login_at)!
        self.user_updated_at = formatter.date(from: user_updated_at)!
    }
    
    // : Get Dummy
    init(user_id: String, user_fb_id: String, user_email: String, user_name: String, user_social_type: String, user_status: UserStatus, user_created_at: Date, user_login_at: Date, user_updated_at: Date) {
        self.user_id = user_id
        self.user_fb_id = user_fb_id
        self.user_email = user_email
        self.user_name = user_name
        self.user_social_type = user_social_type
        self.user_status = user_status.rawValue
        self.user_created_at = user_created_at
        self.user_login_at = user_login_at
        self.user_updated_at = user_updated_at
    }
    
    
    //============================
    // MARK: Func
    //============================
    mutating func addDocsId(docsId: String){
        self.user_fb_id = docsId
    }
    
    mutating func setUserStatus(userSatus: UserStatus){
        self.user_status = userSatus.rawValue
    }
    
    func toDictionary() -> [String: Any] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        
        return [
            "user_id" : self.user_id,
            "user_email" : self.user_email,
            "user_name" : self.user_name,
            "user_social_type" : self.user_social_type,
            "user_status" : self.user_status,
            "user_created_at" : formatter.string(from: self.user_created_at),
            "user_login_at" : formatter.string(from: self.user_login_at),
            "user_updated_at" : formatter.string(from: self.user_updated_at)
        ]
    }
}

//============================
// MARK: Enum
//============================
enum UserStatus: String{
    case active = "Normal: Active User"
    case dormant = "Noraml: Dormant User"
    case unknown = "Caution: Unknown User"
    case unStable = "Caution: UserData has not been completely saved to the repository"
}

enum Providers: String{
    case apple = "Apple"
    case google = "Google"
    case unknown = "Unknown Providers"
}
