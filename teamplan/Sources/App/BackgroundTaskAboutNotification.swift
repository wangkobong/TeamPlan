//
//  BackgroundTask.swift
//  teamplan
//
//  Created by 크로스벨 on 6/7/24.
//  Copyright © 2024 team1os. All rights reserved.
//

import CoreData
import Foundation

final class BackgroundTaskAboutNotification {
    
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
    private let storageManager: LocalStorageManager
    
    private var statData: StatDTO
    private var projectData: [ProjectBackgroundDTO]
    private var myChallengeData: [MyChallengeDTO]

    // state
    private var isProjectRegisted = false
    private var isMyChallengeRegisted = false
    
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
        self.myChallengeData = []
        self.notificationMessage = NotificationData()
        self.storageManager = LocalStorageManager.shared
        
        self.projectNotifyCount = 0
        self.challengeNotifyCount = 0
    }
    
    //MARK: Executor
    
    func executeTask() async -> Bool {
        
        // check data
        if !prepareData() {
            return false
        }
        
        // check notification
        async let isChallengeNotiReady = checkChallengeNotifications()
        async let isProjectNotiReady = checkProjectNotifications()
        
        let results = await [isChallengeNotiReady, isProjectNotiReady]
        if results.allSatisfy({$0}){
            constructNotificationMessage()
            return true
        } else {
            return false
        }
    }
    
    private func constructNotificationMessage() {
        let notifyCount = projectNotifyCount + challengeNotifyCount
        
        notificationMessage.title = "투두팡 목표관리 알림!"
        notificationMessage.message = "\(userName)지키미, 확인해볼 알림이 \(notifyCount)개 있어!"
    }
    
    //MARK: Prepare Properties
    
    private func prepareData() -> Bool {
        let context = storageManager.context
        var results = [Bool]()
        
        return context.performAndWait{
            results = [
                prepareStatData(context: context),
                prepareChallengeData(context: context),
                prepareProjectData(context: context)
            ]
            if results.allSatisfy({$0}){
                return true
            } else {
                print("[BackgroundTask] Failed to prepare data for backgroundTask")
                return false
            }
        }
    }
    
    private func prepareStatData(context: NSManagedObjectContext) -> Bool {
        do {
            guard try statCD.getObject(context: context, userId: userId) else {
                print("[BackgroundTask] Failed to convert StatData")
                return false
            }
            self.statData = StatDTO(with: statCD.object)
            return true
        } catch {
            print("[BackgroundTask] Failed to prepare StatData: \(error.localizedDescription)")
            return false
        }
    }
    
    private func prepareChallengeData(context: NSManagedObjectContext) -> Bool {
        do {
            if self.statData.myChallenges.isEmpty {
                print("[BackgroundTask] There is no ChallengeData to prepare")
                self.isMyChallengeRegisted = false
                return true
            } else {
                guard try challengeCD.getMyObjects(context: context, userId: userId) else {
                    print("[BackgroundTask] Failed to convert MyChallengeData")
                    return false
                }
                self.myChallengeData = challengeCD.objects.map{ MyChallengeDTO(with: $0) }
                self.isMyChallengeRegisted = true
                return true
            }
        } catch {
            print("[BackgroundTask] Failed to prepare ChallengeData")
            return false
        }
    }
    
    private func prepareProjectData(context: NSManagedObjectContext) -> Bool {
        do {
            guard try projectCD.getBackgroundDTOList(context: context, userId: userId) else {
                print("[BackgroundTask] Failed to get ProjectData")
                return false
            }
            if projectCD.backgroundDTO.isEmpty {
                self.isProjectRegisted = false
                return false
            } else {
                self.isProjectRegisted = true
                self.projectData = projectCD.backgroundDTO
                return true
            }
        } catch {
            print("[BackgroundTask] Failed to prepare ProjectData: \(error)")
            return false
        }
    }
    
    //MARK: MyChallenge Notifications
    
    private func checkChallengeNotifications() async -> Bool {
        if isMyChallengeRegisted {
            for challenge in self.myChallengeData {
                if isChallengeNotificationNeeded(for: challenge) {
                    challengeNotifyCount += 1
                }
            }
            print("[BackgroundTask] Notification about challenge: \(challengeNotifyCount)")
            return true
        } else {
            return false
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
    
    private func checkProjectNotifications() async -> Bool {
        if isProjectRegisted {
            let today = Date()
            for project in projectData {
                if isProjectNotificationNeeded(for: project, on: today) {
                    projectNotifyCount += 1
                }
            }
            print("[BackgroundTask] Notification about project: \(projectNotifyCount)")
            return true
        } else {
            return false
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
