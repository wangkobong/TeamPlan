//
//  NotificationModel.swift
//  teamplan
//
//  Created by sungyeon kim on 2023/08/12.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation

struct NotificationSection: Identifiable {
    let id = UUID().uuidString
    let title: String
    let type: NotificationType
    var isSelected: Bool = false
}

struct NotificationModel: Identifiable, Hashable {
    let id = UUID().uuidString
    let title: String
    let description: String
    let type: NotificationType
    var isSelected: Bool
    let date: Date
}

enum NotificationType {
    case all
    case project
    case todo
    case challenge
    case notice
}
