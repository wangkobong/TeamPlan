//
//  SignupLoadingService.swift
//  투두팡
//
//  Created by Crossbell on 8/28/24.
//  Copyright © 2024 team1os. All rights reserved.
//

import CoreData
import Foundation

final class SignupService {
    
    private let userCD = UserServicesCoredata()
    private let statCD = StatisticsServicesCoredata()
    private let challengeCD = ChallengeServicesCoredata()
    private let accessLogCD = AccessLogServicesCoredata()
    private let coreValueCD = CoreValueServicesCoredata()
    
    private let userId: String
    private var userName: String
    private let logHead: Int
    private let signupDate: Date
    
    private var coreValue: CoreValueObject
    private var newProfile: UserObject
    private var newStat: StatisticsObject
    private var newLog: AccessLog
    private var newChallenge: [ChallengeObject]
    
    private let voltManager: VoltManager
    private let storageManager: LocalStorageManager
    
    init() {
        
        self.userId = UUID().uuidString
        self.userName = "unknown"
        self.logHead = 0
        self.signupDate = Date()
        
        self.coreValue = CoreValueObject()
        self.newProfile = UserObject()
        self.newStat = StatisticsObject()
        self.newLog = AccessLog()
        self.newChallenge = []
        
        self.voltManager = VoltManager.shared
        self.storageManager = LocalStorageManager.shared
    }
    
    func executor(with nickName: String) -> Bool {
        setNewUserData(with: nickName)
        
        if storageExecutor() {
            return voltManager.registerUserData(userId: userId, userName: userName)
        } else {
            return false
        }
    }
    
    private func setNewUserData(with nickName: String) {
        self.userName = nickName
        
        // corevalue
        self.coreValue = CoreValueObject(
            userId: userId,
            projectRegistLimit: 5,
            todoRegistLimit: 10,
            dropConvertRatio: 1.0,
            syncCycle: 14
        )
        
        // userData
        self.newProfile = UserObject(
            userId: userId,
            name: nickName,
            userStatus: .active,
            accessLogHead: logHead,
            createdAt: signupDate,
            onlineStatus: false,
            changedAt: signupDate
        )
        
        // statistics
        self.newStat = StatisticsObject(
            userId: userId,
            term: 1,
            drop: 0,
            totalRegistedProjects: 0,
            totalFinishedProjects: 0,
            totalFailedProjects: 0,
            totalAlertedProjects: 0,
            totalExtendedProjects: 0,
            totalRegistedTodos: 0,
            totalFinishedTodos: 0,
            challengeStepStatus: [
                ChallengeType.serviceTerm.rawValue : 1,
                ChallengeType.totalTodo.rawValue : 1,
                ChallengeType.projectAlert.rawValue : 1,
                ChallengeType.projectFinish.rawValue : 1,
                ChallengeType.waterDrop.rawValue : 1
            ],
            mychallenges: [],
            syncedAt: signupDate
        )
        
        // accesslog
        self.newLog = AccessLog(userId: userId, accessDate: signupDate)
        
        // Challenge
        let challengeList = ChallengeList().getData()
        for challenge in challengeList {
            let data = ChallengeObject(
                challengeId: challenge.challengeId,
                userId: userId,
                title: challenge.title,
                desc: challenge.desc,
                goal: challenge.goal,
                type: challenge.type,
                reward: challenge.reward,
                step: challenge.step,
                version: challenge.version,
                status: false,
                lock: challenge.step != 1,
                progress: 0,
                selectStatus: false,
                selectedAt: signupDate,
                unselectedAt: signupDate,
                finishedAt: signupDate
            )
            self.newChallenge.append(data)
        }
    }
    
    private func storageExecutor() -> Bool {
        let context = storageManager.context
        var results = [Bool]()
        
        context.performAndWait {
            results = [
                setNewCoreValue(with: context),
                setNewUserProfile(with: context),
                setNewStat(with: context),
                setNewAccessLog(with: context),
                setNewChallenge(with: context)
            ]
        }
        if results.allSatisfy({$0}) {
            return storageManager.saveContext()
        } else {
            return false
        }
    }
    
    private func setNewCoreValue(with context: NSManagedObjectContext) -> Bool {
        if coreValueCD.setObject(context: context, object: coreValue) {
            print("[SingupLoading] Successfully set CoreValue at storage")
            return true
        } else {
            print("[SingupLoading] Failed to set CoreValue at storage")
            return false
        }
    }
    
    private func setNewUserProfile(with context: NSManagedObjectContext) -> Bool {
        if userCD.setObject(context: context, object: newProfile) {
            print("[SingupLoading] Successfully set UserData at storage")
            return true
        }
        print("[SingupLoading] Failed to set UserData at storage")
        return false
    }
    
    private func setNewStat(with context: NSManagedObjectContext) -> Bool {
        do {
            if try statCD.setObject(context: context, object: newStat) {
                print("[SingupLoading] Successfully set StatData at storage")
                return true
            } else {
                print("[SingupLoading] Failed to set StatData at storage")
                return false
            }
        } catch {
            print("[SingupLoading] \(error.localizedDescription)")
            return false
        }
    }
    
    private func setNewAccessLog(with context: NSManagedObjectContext) -> Bool {
        if accessLogCD.setObject(context: context, object: newLog) {
            print("[SingupLoading] Successfully set AccessLog at storage")
            return true
        } else {
            print("[SingupLoading] Failed to set AccessLog at storage")
            return false
        }
    }
    
    private func setNewChallenge(with context: NSManagedObjectContext) -> Bool {
        for challenge in newChallenge {
            if !challengeCD.setObject(context: context, object: challenge) {
                print("[SingupLoading] Failed to set Challenge at storage: \(challenge.challengeId)")
                return false
            }
        }
        print("[SingupLoading] Successfully set Challenge at storage")
        return true
    }
    
}
