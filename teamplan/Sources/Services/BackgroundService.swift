//
//  BackgroundService.swift
//  투두팡
//
//  Created by Crossbell on 8/24/24.
//  Copyright © 2024 team1os. All rights reserved.
//
import CoreData
import Foundation
import BackgroundTasks

enum BackgroundTaskId: String {
    case notifyTask = "com.team1os.todopang.notifyTask"
}

final class BackgroundService {
    
    private let userId: String
    private let userName: String
    private let compareDate: Date
    
    private var isTaskRegisted: Bool
    
    private let voltManager: VoltManager
    private let storageManager: LocalStorageManager
    
    private let util: Utilities
    private let statCD: StatisticsServicesCoredata
    private let projectCD: ProjectServicesCoredata
    private let challengeCD: ChallengeServicesCoredata
    private let notifyCD: NotificationServicesCoredata
    
    private var previousNotifyList: [NotificationObject]
    
    private var statData: StatisticsObject
    private var projectList: [ProjectObject]
    private var projectNotifyList: [Int : NotificationObject]
    private var challengeList: [ChallengeObject]
    private var challengeNotifyList: [Int : NotificationObject]
    
    private var newNotifyCount: Int
    private var uncheckedNotifyCount: Int
    private var newProjectNotifyCount: Int
    private var newChallengeNotifyCount: Int
    
    init?() {
        self.voltManager = VoltManager.shared
        if let userId = voltManager.getUserId(),
           let userName = voltManager.getUserName() {
            self.userId = userId
            self.userName = userName
            self.isTaskRegisted = voltManager.isBackgroundTaskScheduled()
        } else {
            print("[BackgroundSC] Failed to Initialize ")
            return nil
        }
        self.compareDate = Date()
        self.storageManager = LocalStorageManager.shared
        
        self.util = Utilities()
        self.statCD = StatisticsServicesCoredata()
        self.projectCD = ProjectServicesCoredata()
        self.challengeCD = ChallengeServicesCoredata()
        self.notifyCD = NotificationServicesCoredata()
        
        self.previousNotifyList = []
        
        self.statData = StatisticsObject()
        self.projectList = []
        self.projectNotifyList = [:]
        self.challengeList = []
        self.challengeNotifyList = [:]
        
        self.newNotifyCount = 0
        self.uncheckedNotifyCount = 0
        self.newProjectNotifyCount = 0
        self.newChallengeNotifyCount = 0
    }
    
    //MARK: Main
    
    func notifyExecutor() async -> Bool {
        let context = storageManager.createBackgroundContext()
        
        guard fetchDataExecutor(with: context) else {
            print("[BackgroundSC] Failed to fetch userData at storage")
            return false
        }
        
        guard await countExecutor() else {
            print("[BackgroundSC] Failed to count userData for notify")
            return false
            
        }
        if registExecutor() {
            print("[BackgroundSC] Successfully regist local push message")
        } else {
            print("[BackgroundSC] There is no data for local push message")
        }
        return true
    }
}

//MARK: Scheduling

extension BackgroundService {
    
    func scheduleTaskIfNeeded() {
        
        if self.isTaskRegisted {
            return
        }
        BGTaskScheduler.shared.register(forTaskWithIdentifier: BackgroundTaskId.notifyTask.rawValue, using: nil) { task in
            self.handleBackgroundTask(task: task as! BGAppRefreshTask)
        }
        scheduleTaskIfNeeded()
    }
    
    private func handleBackgroundTask(task: BGAppRefreshTask) {
        Task {
            let result = await notifyExecutor()
            task.setTaskCompleted(success: result)
            scheduleTaskIfNeeded()
        }
    }
    
    private func scheduleNextbackgroundTask() {
        
        // set request
        guard let nextTiming = Calendar.current.nextDate(after: Date(), matching: DateComponents(hour: 6), matchingPolicy: .nextTime) else {
            print("[BackgroundSC] Failed to calculate backgroundTask regist timing")
            return
        }
        let request = BGAppRefreshTaskRequest(identifier: BackgroundTaskId.notifyTask.rawValue)
        request.earliestBeginDate = nextTiming
        
        // regist request
        do {
            try BGTaskScheduler.shared.submit(request)
            _ = voltManager.registerBackgroundTaskScheduled(true)
            print("[BackgroundSC] Background task scheduled at: \(nextTiming)")
        } catch {
            _ = voltManager.registerBackgroundTaskScheduled(false)
            print("[BackgroundSC] Failed to schedule background task")
        }
    }
}

//MARK: Prepare Data

extension BackgroundService {
    
    private func fetchDataExecutor(with context: NSManagedObjectContext) -> Bool {
        var result = [Bool]()
        
        context.performAndWait{
            let isNotifyListFetched = fetchNotifyList(with: context)
            let isStatDataFetched = fetchStatData(with: context)
            let isValidProjectFetched = fetchValidProject(with: context)
            let isMyChallengeFetched = fetchMyChallenges(with: context)
            result = [isNotifyListFetched, isStatDataFetched, isValidProjectFetched, isMyChallengeFetched]
        }
        return result.allSatisfy{$0}
    }
    
    // previous notify
    
    private func fetchNotifyList(with context: NSManagedObjectContext) -> Bool {
        
        if notifyCD.getTotalObjectList(context, with: userId) {
            self.previousNotifyList = notifyCD.objectList
            return true
        } else {
            print("[BackgroundSC] Failed to get notify list from storage")
            return false
        }
    }
    
    // statData
    
    private func fetchStatData(with context: NSManagedObjectContext) -> Bool {
        do {
            guard try statCD.getObject(context: context, userId: userId) else {
                print("[BackgroundSC] Failed to get statData from storage")
                return false
            }
            self.statData = statCD.object
            return true
        } catch {
            print(error.localizedDescription)
            return false
        }
    }
    
    // project
    private func fetchValidProject(with context: NSManagedObjectContext) -> Bool {
        do {
            guard try projectCD.getValidObjects(context: context, with: userId) else {
                print("[BackgroundSC] Failed to get valid project from storage")
                return false
            }
            self.projectList = projectCD.objectList
            return true
        } catch {
            print(error.localizedDescription)
            return false
        }
    }
    
    // myChallenge
    private func fetchMyChallenges(with context: NSManagedObjectContext) -> Bool {
        do {
            guard try challengeCD.getMyObjects(context: context, userId: userId) else {
                print("[BackgroundSC] Failed to get myChallenges from storage")
                return false
            }
            challengeList = challengeCD.objects
            return true
        } catch {
            print(error.localizedDescription)
            return false
        }
    }
}

//MARK: Count Data

extension BackgroundService {
    
    private func countExecutor() async -> Bool {
        
        countUnCheckedNotify()
        return await countNewNotify()
    }
    
    // count and sort previous notify
    private func countUnCheckedNotify() {
        
        if previousNotifyList.isEmpty {
            print("[BackgroundSC] There is no previous notify")
            return
        }
        
        for notify in previousNotifyList {
            if !notify.isCheck {
                uncheckedNotifyCount += 1
            }
            if let projectId = notify.projectId {
                projectNotifyList[projectId] = notify
            }
            if let challengeId = notify.challengeId {
                challengeNotifyList[challengeId] = notify
            }
        }
    }
    
    // count notify include previous & current notify
    private func countNewNotify() async -> Bool {
        
        async let isProjectNotifyCount = countProjectNotify()
        async let isChallengeNotifyCount = countChallengeNotify()
        
        let result = await [isProjectNotifyCount, isChallengeNotifyCount]
        return result.allSatisfy{$0}
    }
    
    private func countProjectNotify() async -> Bool {

        if projectList.isEmpty {
            print("[BackgroundSC] There is no valid project to count notify")
            return true
        }
        
        for project in projectList {
            // check: identify current data
            let candidateNotifyType = identifyProjectForNotify(with: project, on: compareDate)
            
            // update: update previous notify
            if let previousNotify = projectNotifyList[project.projectId],
               candidateNotifyType != previousNotify.projectStatus {
                self.newProjectNotifyCount += 1
            }
            
            // new: create new notify
            if !projectNotifyList.keys.contains(project.projectId) && candidateNotifyType != .ongoing {
                self.newProjectNotifyCount += 1
            }
        }
        return true
    }
    
    private func countChallengeNotify() async -> Bool {
        
        if challengeList.isEmpty {
            print("[NotifySC] There is no registed myChallenge to count notify")
            return true
        }
        
        for challenge in challengeList {
            // check: duplicated with previous notification
            if challengeNotifyList.keys.contains(challenge.challengeId) {
                continue
            }
            // check: identify current data
            let userProgress = getUserProgressForChallengeNotify(with: challenge.type)
            
            // new: create new notify
            if challenge.goal <= userProgress {
                self.newChallengeNotifyCount += 1
            }
        }
        return true
    }
}

//MARK: Regist LocalPush

extension BackgroundService {
    
    private func registExecutor() -> Bool {
        
        if isLocalPushNeed() {
            registToLocalPush(with: userName)
            return true
        } else {
            return false
        }
    }

    private func isLocalPushNeed() -> Bool {
        if self.uncheckedNotifyCount == 0 && self.newProjectNotifyCount == 0 && self.newChallengeNotifyCount == 0 {
            return false
        } else {
            return true
        }
    }
    
    private func registToLocalPush(with userName: String) {
        let totalNewNotifyCount = self.newProjectNotifyCount + self.newChallengeNotifyCount
        
        let notifyTitle = "투두팡 목표알림!"
        let notifyMessage = "\(userName) 지킴이! 아직 확인하지은 알람이 \(self.uncheckedNotifyCount)개, 새로운 알람이 \(totalNewNotifyCount)개 있어!"
        
        LocalPushManager.scheduleLocalPush(title: notifyTitle, message: notifyMessage, at: Date())
    }
}

//MARK: Util

extension BackgroundService {
    
    func identifyProjectForNotify(with object: ProjectObject, on tomorrow: Date) -> ProjectNotification {
        do {
            let totalPeriod = try util.calculateDatePeriod(with: object.startedAt, and: object.deadline)
            let progressedPeriod = try util.calculateDatePeriod(with: object.startedAt, and: tomorrow)
            
            if progressedPeriod == totalPeriod / 2 {
                return .halfway
                
            } else if progressedPeriod == (totalPeriod * 3 / 4) {
                return .nearDeadline
                
            } else if progressedPeriod == (totalPeriod - 1) {
                return .oneDayLeft
                
            } else if progressedPeriod == totalPeriod {
                return .theDay
                
            } else if progressedPeriod > totalPeriod {
                return .explode
                
            } else {
                return .ongoing
            }
        } catch {
            print("[NotifyService] Failed to calculate project period")
            return .unknown
        }
    }
    
    func getUserProgressForChallengeNotify(with type: ChallengeType) -> Int {
        switch type {
        case .onboarding:
            return 1
        case .serviceTerm:
            return statData.term
        case .totalTodo:
            return statData.totalRegistedTodos
        case .projectAlert:
            return statData.totalAlertedProjects
        case .projectFinish:
            return statData.totalFinishedProjects
        case .waterDrop:
            return statData.drop
        case .unknownType:
            return 0
        }
    }
}
