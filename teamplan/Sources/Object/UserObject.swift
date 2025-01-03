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
    case apple = "apple.com"
    case google = "google.com"
    case firebase = "firebase.com"
    case unknown = "Unknown Providers"
}

// MARK: - Object
struct UserObject{
    
    let userId: String
    let name: String
    let userStatus: UserStatus
    let accessLogHead: Int
    let createdAt: Date
    
    let onlineStatus: Bool
    let changedAt: Date
    
    let serverId: String?
    let email: String?
    let socialType: Providers?
    let syncedAt: Date?
    
    init(
        userId: String,
        name: String,
        userStatus: UserStatus,
        accessLogHead: Int,
        createdAt: Date,
        onlineStatus: Bool,
        changedAt: Date,
        serverId: String? = nil,
        email: String? = nil,
        socialType: Providers? = nil,
        syncedAt: Date? = nil
    ) {
        self.userId = userId
        self.name = name
        self.userStatus = userStatus
        self.accessLogHead = accessLogHead
        self.createdAt = createdAt
        self.onlineStatus = onlineStatus
        self.changedAt = changedAt
        self.serverId = serverId
        self.email = email
        self.socialType = socialType
        self.syncedAt = syncedAt
    }
    
    init(temp: Date = Date()) {
        self.userId = "unknown"
        self.name = "unknown"
        self.userStatus = .unknown
        self.accessLogHead = 0
        self.createdAt = temp
        self.onlineStatus = false
        self.changedAt = temp
        self.serverId = "unknown"
        self.email = "unknown"
        self.socialType = .unknown
        self.syncedAt = temp
    }
}


