//
//  BackgroundTask.swift
//  teamplan
//
//  Created by 크로스벨 on 6/7/24.
//  Copyright © 2024 team1os. All rights reserved.
//

import Foundation

final class BackgroundTask {
    
    // shared
    var notificationMessage: NotificationData
    var projectNotifyCount: Int
    var challengeNotifyCount: Int
    
    // private
    private let util: Utilities
    private let statCD: StatisticsServicesCoredata
    private let challengeCD: ChallengeServicesCoredata
    private let projectCD: ProjectServicesCoredata
    private let notifySC: NotificationService
    
    private let userId: String
    private let userName: String
    
    private var statData: StatDTO
    private var projectData: [ProjectBackgroundDTO]
    private var challengeData: [MyChallengeDTO]

    
    init(userId: String, userName: String) {
        self.util = Utilities()
        self.statCD = StatisticsServicesCoredata()
        self.challengeCD = ChallengeServicesCoredata()
        self.projectCD = ProjectServicesCoredata()
        self.notifySC = NotificationService()
        
        self.userId = userId
        self.userName = userName
        self.statData = StatDTO()
        self.projectData = []
        self.challengeData = []
        self.notificationMessage = NotificationData()
        
        self.projectNotifyCount = 0
        self.challengeNotifyCount = 0
    }
    
    //MARK: Executor
    
    func executeTask() async -> Bool {
        // check data
        if await !checkData() {
            return false
        }
        await checkProjectNotifications()
        await checkChallengeNotifications()
        
        if projectNotifyCount == 0 && challengeNotifyCount == 0 {
            return false
        }
        
        constructNotificationMessage()
        return true
    }
    
    private func constructNotificationMessage() {
        let notifyCount = projectNotifyCount + challengeNotifyCount
        
        notificationMessage.title = "투두팡 목표관리 알림!"
        notificationMessage.message = "\(userName)지키미, 확인해볼 알림이 \(notifyCount)개 있어!"
    }
    
    //MARK: Prepare Properties
    
    private func checkData() async -> Bool {
        let max = 3
        var retryCount = 0
        var isDataReady = false
        
        // Prepare Data
        while retryCount < max && !isDataReady {
            isDataReady = await prepareData()
    
            if !isDataReady {
                retryCount += 1
            }
        }
        if !isDataReady {
            print("[BackgroundTask] Failed to prepare data after \(max) retries")
            return false
        }
        return true
    }
    
    private func prepareData() async -> Bool {
        async let statReady = prepareStatData()
        async let challengeReady = prepareChallengeData()
        async let projectReady = prepareProjectData()
        
        let results = await [statReady, challengeReady, projectReady]
        return results.allSatisfy { $0 }
    }
    
    private func prepareStatData() async -> Bool {
        do {
            self.statData = StatDTO(with: try statCD.getObject(with: userId))
            return true
        } catch {
            print("[BackgroundTask] Failed to prepare StatData")
            return false
        }
    }
    
    private func prepareChallengeData() async -> Bool {
        do {
            let myChallenges = statData.myChallenges
            for challengeId in myChallenges {
                let challenge = try await challengeCD.getObject(with: challengeId, and: userId)
                self.challengeData.append(MyChallengeDTO(with: challenge))
            }
            return true
        } catch {
            print("[BackgroundTask] Failed to prepare ChallengeData")
            return false
        }
    }
    
    private func prepareProjectData() async -> Bool {
        do {
            self.projectData = try projectCD.getBackgroundDTOList(with: userId)
            return true
        } catch {
            print("[BackgroundTask] Failed to prepare ProjectData")
            return false
        }
    }
    
    //MARK: Challenge Notifications
    
    private func checkChallengeNotifications() async {
        if challengeData.isEmpty { return }
        for challenge in challengeData {
            if isChallengeNotificationNeeded(for: challenge) {
                challengeNotifyCount += 1
            }
        }
    }
    
    private func isChallengeNotificationNeeded(for challenge: MyChallengeDTO) -> Bool {
        switch challenge.type {
        case .projectAlert:
            return challenge.goal <= statData.totalAlertedProjects
        case .projectFinish:
            return challenge.goal <= statData.totalFinishedProjects
        case .serviceTerm:
            return challenge.goal <= statData.term
        case .totalTodo:
            return challenge.goal <= statData.totalRegistedTodos
        case .waterDrop:
            return challenge.goal <= statData.drop
        default:
            return false
        }
    }
    
    //MARK: Project Notifications
    
    private func checkProjectNotifications() async {
        if projectData.isEmpty { return }
        let today = Date()
        for project in projectData {
            if isProjectNotificationNeeded(for: project, on: today) {
                projectNotifyCount += 1
            }
        }
    }
    
    private func isProjectNotificationNeeded(for project: ProjectBackgroundDTO, on date: Date) -> Bool {
        do {
            let totalPeriod = try util.calculateDatePeriod(with: project.startedAt, and: project.deadline)
            let progressedPeriod = try util.calculateDatePeriod(with: project.startedAt, and: date)
            let milestone = [totalPeriod / 2, totalPeriod * 3 / 4, totalPeriod - 1, totalPeriod]
            
            return milestone.contains(progressedPeriod) || progressedPeriod > totalPeriod
        } catch {
            print("[BackgroundTask] Failed to calculate project period")
            return false
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
