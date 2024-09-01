//
//  LocalPushManager.swift
//  투두팡
//
//  Created by Crossbell on 8/24/24.
//  Copyright © 2024 team1os. All rights reserved.
//

import Foundation
import UserNotifications

final class LocalPushManager {
    
    static func scheduleLocalPush(title: String, message: String, at date: Date) {
        
        // user notification authorization check
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else {
                print("[LocalPushManager] Notification not authorized.")
                return
            }
            
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = message
            content.sound = .default
            
            guard let timing = Calendar.current.nextDate(after: date, matching: DateComponents(hour: 9), matchingPolicy: .nextTime) else {
                print("[LocalPushManager] Failed to calculate next notification timing.")
                return
            }
            
            let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: timing)
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("[LocalPushManager] Failed to schedule notification: \(error.localizedDescription)")
                } else {
                    print("[LocalPushManager] Notification scheduled at \(timing)")
                }
            }
        }
    }
    
    static func mockLocalPush(title: String, message: String) {
        
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else {
                print("[LocalPushManager] Notification not authorized.")
                return
            }
            
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = message
            content.sound = .default
            
            let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: Date().addingTimeInterval(60))
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("[LocalPushManager] Failed to schedule notification: \(error.localizedDescription)")
                } else {
                    print("[LocalPushManager] Notification scheduled for \(triggerDate)")
                }
            }
        }
    }
}
