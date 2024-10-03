//
//  ChallengeManager.swift
//  teamplan
//
//  Created by 크로스벨 on 6/13/24.
//  Copyright © 2024 team1os. All rights reserved.
//
import CoreData
import Foundation

final class ChallengeNotifyManager {
    
    private let userId: String
    
    private let statCD: StatisticsServicesCoredata
    private let notifyCD: NotificationServicesCoredata
    private let challengeCD: ChallengeServicesCoredata
    private let storageManager: LocalStorageManager
    
    private var statData: StatisticsObject
    private var myChallengeList: [MyChallengeDTO]
    private var newNotifyList: [NotificationObject]
    private var previousNotifyList: [NotificationObject]
    
    // for porjectService
    init(
        userId: String,
        storageManager: LocalStorageManager
    ) {
        self.userId = userId
        self.statCD = StatisticsServicesCoredata()
        self.notifyCD = NotificationServicesCoredata()
        self.challengeCD = ChallengeServicesCoredata()
        self.storageManager = storageManager
        
        self.statData = StatisticsObject()
        self.myChallengeList = []
        self.newNotifyList = []
        self.previousNotifyList = []
    }
    
    // for challengeService
    init(
        userId: String,
        statCD: StatisticsServicesCoredata,
        challengeCD: ChallengeServicesCoredata,
        storageManager: LocalStorageManager,
        myChallenges: [MyChallengeDTO]
    ) {
        self.userId = userId
        self.statCD = statCD
        self.notifyCD = NotificationServicesCoredata()
        self.challengeCD = challengeCD
        self.storageManager = storageManager
        
        self.statData = StatisticsObject()
        self.myChallengeList = myChallenges
        self.newNotifyList = []
        self.previousNotifyList = []
    }
    
    func updateMyChallenges(with challengeList: [MyChallengeDTO]){
        self.myChallengeList = challengeList
    }
    
    //MARK: Main
    
    // for projectService
    func projectExecutor() -> Bool {
        let today = Date()
        let context = storageManager.context
        
        guard fetchStatData(with: context) else {
            return false
        }
        
        guard fetchMyChallenges(with: context) else {
            return false
        }
        
        guard fetchNotify(context) else {
            return false
        }
        
        return checkProcedure(context, at: today)
    }
    
    // for challengeService
    func challengeExecutor() -> Bool {
        let today = Date()
        let context = storageManager.context
        
        guard fetchStatData(with: context) else {
            return false
        }
        
        guard fetchNotify(context) else {
            return false
        }
        
        return checkProcedure(context, at: today)
    }
    
    // main function
    private func checkProcedure(_ context: NSManagedObjectContext, at date: Date) -> Bool {
        
        // check: myChallenges
        if myChallengeList.isEmpty {
            print("[NotifyManager] There is no registed myChallenge")
            return true
        } else {
            for challenge in myChallengeList {
                let isChallengeCanAccomplish = challenge.goal <= challenge.progress
                let isNotifyExist = !isNotifyExist(with: challenge.challengeID)
                
                if isChallengeCanAccomplish && isNotifyExist {
                    let newNotify = createNewNotify(with: challenge, at: date)
                    self.newNotifyList.append(newNotify)
                }
            }
        }
        
        // check: Notify
        if newNotifyList.isEmpty {
            print("[NotifyManager] There is no no achievable myChallenge")
            return true
        } else {
            return context.performAndWait {
                for notify in newNotifyList {
                    notifyCD.setObject(context, object: notify)
                }
                return storageManager.saveContext()
            }
        }
    }
}

//MARK: Support

extension ChallengeNotifyManager {

    private func fetchStatData(with context: NSManagedObjectContext) -> Bool {
        do {
            guard try statCD.getObject(context: context, userId: userId) else {
                print("[NotifyManager] Error detected while converting StatEntity to object")
                return false
            }
            self.statData = statCD.object
            return true
        } catch {
            print(error.localizedDescription)
            return false
        }
    }
    
    private func fetchMyChallenges(with context: NSManagedObjectContext) -> Bool {
        do {
            guard try challengeCD.getMyObjects(context: context, userId: userId) else {
                print("[NotifyManager] Failed to get myChallenges")
                return false
            }
            let challengeList = challengeCD.objects
            for challenge in challengeList {
                let progress = getUserProgress(with: challenge.type)
                self.myChallengeList.append(MyChallengeDTO(object: challenge, progress: progress))
            }
            return true
        } catch {
            print(error.localizedDescription)
            return false
        }
    }
    
    private func fetchNotify(_ context: NSManagedObjectContext) -> Bool {
        guard notifyCD.fetchCategoryObjectlist(context, with: userId, type: .challenge) else {
            print("[NotifyManager] Failed to get previous challenge notify")
            return false
        }
        self.previousNotifyList = notifyCD.objectList
        print("[NotifyManager] previous notify: \(self.previousNotifyList)")
        return true
    }
    
    private func isNotifyExist(with challengeId: Int) -> Bool {
        return self.previousNotifyList.contains(where: { $0.challengeId == challengeId })
    }
    
    private func createNewNotify(with dto: MyChallengeDTO, at date: Date) -> NotificationObject {
        return NotificationObject(
            userId: userId,
            challengeId: dto.challengeID,
            challengeStatus: .canAchieve,
            category: .challenge,
            title: dto.title,
            desc: "'\(dto.title)' 도전과제가 완료 가능합니다!",
            updateAt: date,
            isCheck: false
        )
    }
    
    private func getUserProgress(with type: ChallengeType) -> Int {
        switch type {
        case .onboarding:
            return 1
        case .serviceTerm:
            return statData.term
        case .totalTodo:
            return statData.totalRegistedTodos
        case .projectAlert:
            return statData.totalFailedProjects
        case .projectFinish:
            return statData.totalFinishedProjects
        case .waterDrop:
            return statData.drop
        case .unknownType:
            return 0
        }
    }
}
