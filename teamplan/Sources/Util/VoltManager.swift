//
//  VoltManager.swift
//  투두팡
//
//  Created by Crossbell on 8/24/24.
//  Copyright © 2024 team1os. All rights reserved.
//

import Foundation
import SwiftUI
import KeychainSwift

final class VoltManager {

    static let shared = VoltManager()

    private let keychain = KeychainSwift()
    private let userDefaults = UserDefaults.standard

    private var userId: String?
    private var userName: String?

    private init() {
        self.userId = getUserId()
        self.userName = getUserName()
    }
    
    // MARK: - Set
    
    func registerUserData(userId: String, userName: String) -> Bool {
        self.userId = userId
        self.userName = userName
        
        let isRegisteredInUserDefault = registerUserDataToUserDefaults(userId: userId, userName: userName)
        let isRegisteredInKeyChain = registerUserDataToKeyChain(userId: userId, userName: userName)
        
        return isRegisteredInUserDefault && isRegisteredInKeyChain
    }
    
    private func registerUserDataToKeyChain(userId: String, userName: String) -> Bool {
        let isUserIdSet = self.keychain.set(userId, forKey: KeyChainArgs.identifier.rawValue)
        let isUserNameSet = self.keychain.set(userName, forKey: KeyChainArgs.userName.rawValue)
        return isUserIdSet && isUserNameSet
    }
    
    private func registerUserDataToUserDefaults(userId: String, userName: String) -> Bool {
        userDefaults.set(userId, forKey: UserDefaultKey.userId.rawValue)
        userDefaults.set(userName, forKey: UserDefaultKey.username.rawValue)
        
        guard let storedUserId = userDefaults.string(forKey: UserDefaultKey.userId.rawValue),
              let storedUserName = userDefaults.string(forKey: UserDefaultKey.username.rawValue)
        else {
            print("[VoltManager] Failed to Register UserData to UserDefaults")
            return false
        }
        
        if (userId == storedUserId) && (userName == storedUserName) {
            return true
        } else {
            print("[VoltManager] Unstable UserData is Registered in UserDefaults")
            return false
        }
    }
    
    func registerBackgroundTaskScheduled(_ isRegistered: Bool) -> Bool {
        userDefaults.set(isRegistered, forKey: UserDefaultKey.taskRegisted.rawValue)
        
        let storedRegistered = userDefaults.bool(forKey: UserDefaultKey.taskRegisted.rawValue)
        if isRegistered == storedRegistered {
            return true
        } else {
            print("[VoltManager] Failed to Register 'BackgroundTask Scheduled' to UserDefaults")
            return false
        }
    }
    // MARK: - Get
    
    func getUserId() -> String? {
        if let userId = self.userId {
            return userId
        }
        if let userId = userDefaults.string(forKey: UserDefaultKey.userId.rawValue) {
            return userId
        }
        return keychain.get(KeyChainArgs.identifier.rawValue)
    }
    
    func getUserName() -> String? {
        if let userName = self.userName {
            return userName
        }
        if let userName = userDefaults.string(forKey: UserDefaultKey.username.rawValue) {
            return userName
        }
        return keychain.get(KeyChainArgs.userName.rawValue)
    }
    
    func isBackgroundTaskScheduled() -> Bool {
        return userDefaults.bool(forKey: UserDefaultKey.taskRegisted.rawValue)
    }
    
    // MARK: - Delete
    
    func clear() -> Bool {
        userId = nil
        userName = nil
        return clearUserDefault() && clearKeyChain()
    }

    private func clearUserDefault() -> Bool {
        userDefaults.removeObject(forKey: UserDefaultKey.userId.rawValue)
        userDefaults.removeObject(forKey: UserDefaultKey.username.rawValue)
        userDefaults.removeObject(forKey: UserDefaultKey.taskRegisted.rawValue)

        let isUserIdRemoved = userDefaults.string(forKey: UserDefaultKey.userId.rawValue) == nil
        let isUserNameRemoved = userDefaults.string(forKey: UserDefaultKey.username.rawValue) == nil
        let isBackgroundTaskRegistedRemoved = userDefaults.object(forKey: UserDefaultKey.taskRegisted.rawValue) == nil

        return isUserIdRemoved && isUserNameRemoved && isBackgroundTaskRegistedRemoved
    }

    private func clearKeyChain() -> Bool {
        let isUserIdRemovedFromKeychain = keychain.delete(KeyChainArgs.identifier.rawValue)
        let isUserNameRemovedFromKeychain = keychain.delete(KeyChainArgs.userName.rawValue)
        return isUserIdRemovedFromKeychain && isUserNameRemovedFromKeychain
    }
    
    // MARK: - Enum
    
    private enum UserDefaultKey: String {
        case userId = "userIdKey"
        case username = "userNameKey"
        case taskRegisted = "backgroundTaskRegistedKey"
        case isFirstLaunch = "isFirstLaunchKey"
    }

    private enum KeyChainArgs: String {
        case identifier = "identifier"
        case userName = "userName"
    }

    func performFirstLaunchSetupIfNeeded() {
        if userDefaults.bool(forKey: UserDefaultKey.isFirstLaunch.rawValue) == false {
            _ = clear()
            userDefaults.set(true, forKey: UserDefaultKey.isFirstLaunch.rawValue)
            userDefaults.synchronize()
        }
    }
}
