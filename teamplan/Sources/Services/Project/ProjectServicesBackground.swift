//
//  ProjectServicesBackground.swift
//  teamplan
//
//  Created by 크로스벨 on 5/28/24.
//  Copyright © 2024 team1os. All rights reserved.
//

import Foundation

final class ProjectServicesBackground {
    
    private let util: Utilities
    private let projectCD: ProjectServicesCoredata
    
    private let userId: String
    private let userName: String

    var projectNotifyCount: Int
    var notificationMessage: NotificationData
    
    
    init(userId: String, userName: String) {
        self.util = Utilities()
        self.projectCD = ProjectServicesCoredata()
        
        self.userId = userId
        self.userName = userName
        self.projectNotifyCount = 0
        self.notificationMessage = NotificationData()
    }
    
    //MARK: Executor
    
    func isPushMessageReady() async -> Bool {
        
        await fetchProjectNotifications()
        if projectNotifyCount == 0 {
            print("[ProjectBG] There are no projects that need to be notify.")
            return false
        }
        constructMessage()
        return true
    }
    
    //MARK: Struct Message
    
    private func constructMessage() {
        
        // Title
        notificationMessage.title = "투두팡 목표관리 알림!"
        // Body
        notificationMessage.message = "\(userName)지키미, 확인해볼 목표가 \(projectNotifyCount)개 있어!"
    }

    //MARK: Check Project
    
    
    private func fetchProjectNotifications() async {
        let today = Date()
        
        do {
            let projectObjects = try projectCD.getTargetObjects(with: userId)
            for project in projectObjects {
                calculateProjectNotify(with: project, and: today)
            }
        } catch {
            print("[BackgroundTask] Failed to prepare project notification list: \(error.localizedDescription)")
            projectNotifyCount = 0
        }
    }
    
    private func calculateProjectNotify(with object: ProjectObject, and today: Date) {

        do {
            let totalPeriod = try util.calculateDatePeroid(with: object.startedAt, and: object.deadline)
            let progressedPeriod = try util.calculateDatePeroid(with: object.startedAt, and: today)
            
            let halfwayPoint = totalPeriod / 2
            let nearDeadlinePoint = totalPeriod * 3 / 4
            
            if progressedPeriod == halfwayPoint ||
               progressedPeriod == nearDeadlinePoint ||
               progressedPeriod == totalPeriod - 1 {
                projectNotifyCount += 1
            }
        } catch {
            print("[BackgroundTask] Failed to calculate project period: \(error.localizedDescription)")
        }
    }
}

//MARK: Entity

struct NotificationData {
    var title: String
    var message: String
    
    init() {
        self.title = "잘못된 목표"
        self.message = "잘못된 메세지"
    }
    
    init(title: String,
         message: String)
    {
        self.title = title
        self.message = message
    }
}
