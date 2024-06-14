//
//  NotificationObject.swift
//  teamplan
//
//  Created by 크로스벨 on 6/3/24.
//  Copyright © 2024 team1os. All rights reserved.
//

import Foundation

// MARK: - Object
struct NotificationObject {
    let userId: String
    let projectId: Int?
    let challengeId: Int?
    let category: NotificationCategory
    let title: String
    let desc: String
    let date: Date
    let isCheck: Bool
    
    // Default initializer for unknown type
    init() {
        self.userId = "unknown"
        self.projectId = nil
        self.challengeId = nil
        self.category = .unknown
        self.title = "unknown"
        self.desc = "unknown"
        self.date = Date()
        self.isCheck = false
    }
    
    // Initializer for specific types
    init(
         userId: String,
         projectId: Int? = nil,
         challengeId: Int? = nil,
         type: NotificationCategory,
         title: String,
         desc: String,
         date: Date,
         isCheck: Bool)
    {
        self.userId = userId
        self.projectId = projectId
        self.challengeId = challengeId
        self.category = type
        self.title = title
        self.desc = desc
        self.date = date
        self.isCheck = isCheck
    }
}

// MARK: - Enum

enum NotificationCategory: Int {
    case unknown = 0
    case project = 1
    case challenge = 2
}

enum projectNotification: Int {
    case unknown = 0
    case ongoing = 1
    case halfway = 2
    case nearDeadline = 3
    case oneDayLeft = 4
    case theDay = 5
    case explode = 6
}

enum challengeNoitification: Int {
    case unknown = 0
    case canAchieve = 1
    case canChallenge = 2
}

enum NotificationDesc {
    case halfway(userName: String, title: String)
    case nearDeadline(userName: String, title: String, dayLeft: Int)
    case oneDayBefore(userName: String, title: String)
    case deadline(userName: String, title: String)
    case doomsDay(userName: String, title: String)
    case challenge(userName: String, title: String)
    
    var toString: String {
        switch self {
        case .halfway(let name, let title):
            return "\(name) 지킴이! \(title) 마감까지 절반 남았어!"
        case .nearDeadline(let name, let title, let dayLeft):
            return "\(name) 지킴이! \(title) 마감까지 \(dayLeft)일 밖에 남지않았어!"
        case .oneDayBefore(let name, let title):
            return "\(name) 지킴이! \(title) 마감이 내일이야! 폭탄맨이 커지지 않게 주의해줘!"
        case .deadline(let name, let title):
            return "\(name) 지킴이! 오늘은 \(title) 마감일이야! 폭탄맨이 위험해하니 목표를 완료해줘!"
        case .doomsDay(let name, let title):
            return "결국 그날이 오고 말았습니다 \(name)지킴이... \(title)은 먼지가 되었으며, 폭탄맨은 한줌의 재가 되어 사라졌습니다... \n무엇을 위한 희생이였나요...?"
        case .challenge(let name, let title):
            return "\(name) 지킴이! 완료 가능한 도전과제 '\(title)' 를 확인해줘!"
        }
    }
}

