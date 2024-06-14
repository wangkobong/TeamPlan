//
//  NotificationService.swift
//  teamplan
//
//  Created by 크로스벨 on 6/3/24.
//  Copyright © 2024 team1os. All rights reserved.
//

import Foundation

final class NotificationService {
    
    private let util = Utilities()
    private let notifyCD = NotificationServicesCoredata()
    
    func createNotify(with object: NotificationObject) async -> Bool {
        do {
            try await notifyCD.setObject(with: object)
            print("[NotifyService] Successfully set notify")
            return true
        } catch {
            print("[NotifyService] Failed to set notify: \(error.localizedDescription)")
            return false
        }
    }
    
    func getFullNotify(with userId: String) async -> [NotificationObject] {
        do {
            return try await notifyCD.getFullObject(with: userId)
        } catch {
            print("[NotifyService] Failed to get full notify")
            return [NotificationObject()]
        }
    }
    
    func getCategoryNotify(with userId: String, and category: NotificationCategory) async -> [NotificationObject] {
        do {
            return try await notifyCD.getCategoryObject(with: userId, and: category)
        } catch {
            print("[NotifyService] Failed to get category notify")
            return [NotificationObject()]
        }
    }
    
    func deleteNotify(with userId: String, and notifyId: Int) async {
        do {
            try await notifyCD.deleteObject(with: userId, and: notifyId)
        } catch {
            print("[NotifyService] Failed to delete notify")
        }
    }
    
    func deleteNotifyList(with userId: String, and notifyList: [Int]) async {
        do {
            try await notifyCD.deleteObjects(with: userId, and: notifyList)
        } catch {
            print("[NotifyService] Failed to delete notifyList")
        }
    }
    
    func identifyProjectForNotify(with object: ProjectObject, on today: Date) async -> projectNotification {
        do {
            let totalPeriod = try util.calculateDatePeriod(with: object.startedAt, and: object.deadline)
            let progressedPeriod = try util.calculateDatePeriod(with: object.startedAt, and: today)
            
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
}
