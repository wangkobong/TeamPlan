//
//  LiteNotifyService.swift
//  투두팡
//
//  Created by Crossbell on 9/23/24.
//  Copyright © 2024 team1os. All rights reserved.
//
import CoreData
import Foundation

final class LiteNotifyService {
    
    var notifyList: [NotificationObject]
    
    private let userId: String
    private let notifyCD: NotificationServicesCoredata
    private let storageManager: LocalStorageManager
    
    init(userId: String) {
        self.notifyList = []
        self.userId = userId
        self.notifyCD = NotificationServicesCoredata()
        self.storageManager = LocalStorageManager.shared
    }
    
    func fetchNotifyList() async -> Bool {
        self.notifyList = []
        let context = storageManager.context
        guard notifyCD.fetchTotalObjectList(context, with: userId) else {
            print("[LiteNotifySC] Failed to fetch notifyList")
            return false
        }
        self.notifyList = notifyCD.objectList
        return true
    }
    
    func checkedNotifyProcedure(with dto: NotifyUpdateDTO) -> Bool {
        let context = storageManager.context
        
        if notifyCD.updateObject(context, dto: dto) {
            guard storageManager.saveContext() else {
                print("[LiteNotifySC] Failed to apply update result to storage")
                return false
            }
            print("[LiteNotifySC] Successfully apply isCheck Status at storage")
            return true
        } else {
            return false
        }
    }
}
