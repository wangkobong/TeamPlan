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
    
    private let util: Utilities
    private let notifySC: NotificationService
    
    private let voltManager: VoltManager
    private let storageManager: LocalStorageManager
    
    private var uncheckProjectNotify: Int
    private var uncheckChallengeNotify: Int
    
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
        self.notifySC = NotificationService(userId: self.userId, processedDate: self.compareDate)

        self.uncheckProjectNotify = 0
        self.uncheckChallengeNotify = 0
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
        scheduleNextbackgroundTask()
    }
    
    private func handleBackgroundTask(task: BGAppRefreshTask) {
        Task {
            let result = await notifyExecutor()
            task.setTaskCompleted(success: result)
            scheduleNextbackgroundTask()
        }
    }
    
    private func scheduleNextbackgroundTask() {
        
        let calendar = Calendar.current
        let now = Date()
        
        var nextTiming = calendar.nextDate(after: now, matching: DateComponents(hour: 6), matchingPolicy: .nextTime)
        
        if let nextTimingUnwrapped = nextTiming, nextTimingUnwrapped <= now {
            nextTiming = calendar.date(byAdding: .day, value: 1, to: nextTimingUnwrapped)
        }

        guard let validNextTiming = nextTiming else {
            print("[BackgroundSC] Failed to calculate backgroundTask regist timing")
            return
        }

        let request = BGAppRefreshTaskRequest(identifier: BackgroundTaskId.notifyTask.rawValue)
        request.earliestBeginDate = validNextTiming
        
        // regist request
        do {
            try BGTaskScheduler.shared.submit(request)
            _ = voltManager.registerBackgroundTaskScheduled(true)
            print("[BackgroundSC] Background task scheduled at: \(validNextTiming)")
        } catch {
            _ = voltManager.registerBackgroundTaskScheduled(false)
            print("[BackgroundSC] Failed to schedule background task: \(error.localizedDescription)")
        }
    }
}

//MARK: Notify

extension BackgroundService {
    
    func notifyExecutor() async -> Bool {
        
        guard await notifySC.backgroundExecutor() else {
            print("[BackgroundSC] Failed to process notify service")
            return false
        }
        await countData()
        
        if registExecutor() {
            print("[BackgroundSC] Successfully regist local push message")
        } else {
            print("[BackgroundSC] There is no data for local push message")
        }
        return true
    }
    
    private func countData() async {

        let notifyList = await notifySC.notifyDataManager.getNotify()
        for notify in notifyList {
            
            if !notify.isCheck && notify.category == .project {
                self.uncheckProjectNotify += 1
            }
            
            if !notify.isCheck && notify.category == .challenge {
                self.uncheckChallengeNotify += 1
            }
        }
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
        if self.uncheckProjectNotify == 0 && self.uncheckChallengeNotify == 0 {
            return false
        } else {
            return true
        }
    }
    
    private func registToLocalPush(with userName: String) {
        let notifyTitle = "투두팡 목표알림"
        let notifyMessage = "\(userName) 지킴이! 아직 확인하지 않은 목표알람이 \(self.uncheckProjectNotify)개, 도전과제 알람이 \(self.uncheckChallengeNotify)개 있습니다."
        
        LocalPushManager.scheduleLocalPush(title: notifyTitle, message: notifyMessage, at: Date())
    }
}
