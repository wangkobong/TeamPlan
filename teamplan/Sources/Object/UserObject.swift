//
//  UserObject.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/08/22.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation

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


// MARK: - Object
struct UserObject{
    
    let userId: String
    let email: String
    let name: String
    let socialType: Providers
    let status: UserStatus
    let accessLogHead: Int
    let createdAt: Date
    let changedAt: Date
    let syncedAt: Date
    
    init(
        userId: String,
         email: String,
         name: String,
         socialType: Providers,
         status: UserStatus,
         accessLogHead: Int,
         createdAt: Date,
         changedAt: Date,
         syncedAt: Date) 
    {
        self.userId = userId
        self.email = email
        self.name = name
        self.socialType = socialType
        self.status = status
        self.accessLogHead = accessLogHead
        self.createdAt = createdAt
        self.changedAt = changedAt
        self.syncedAt = syncedAt
    }
}


