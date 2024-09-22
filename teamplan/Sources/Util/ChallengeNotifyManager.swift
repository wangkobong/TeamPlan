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
    
    private let statCD: StatisticsServicesCoredata
    private let notifyCD: NotificationServicesCoredata
    private let challengeCD: ChallengeServicesCoredata
    
    private let userId: String
    
    private var statData: StatisticsObject
    private var challengeList: [ChallengeObject]
    private var newNotifyList: [NotificationObject]
    
    init(userId: String) {
        self.statCD = StatisticsServicesCoredata()
        self.notifyCD = NotificationServicesCoredata()
        self.challengeCD = ChallengeServicesCoredata()
        
        self.userId = userId
        
        self.statData = StatisticsObject()
        self.challengeList = []
        self.newNotifyList = []
    }

    func isNotifyNeed(_ context: NSManagedObjectContext) -> Bool {
        
        guard fetchStatData(with: context) else {
            return false
        }
        
        guard fetchMyChallenges(with: context) else {
            return false
        }
        
        if self.challengeList.isEmpty {
            print("[ChallengeNotifyManager] There is no myChallenge to check")
            return true
        }
        
        for challenge in challengeList {
            let userProgress = getUserProgress(with: challenge.type)
            if challenge.goal <= userProgress {
                self.newNotifyList.append(createNotify(with: challenge))
            }
        }
        
        if self.newNotifyList.isEmpty {
            print("[ChallengeNotifyManager] There is no myChallenge can complete")
            return true
        }
        
        for notify in newNotifyList {
            notifyCD.setObject(context, object: notify)
        }
        return true
    }
    
    private func fetchStatData(with context: NSManagedObjectContext) -> Bool {
        do {
            guard try statCD.getObject(context: context, userId: userId) else {
                print("[NotifySC] Error detected while converting StatEntity to object")
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
                print("[NotifySC] Failed to get myChallenges")
                return false
            }
            self.challengeList = challengeCD.objects
            return true
        } catch {
            print(error.localizedDescription)
            return false
        }
    }
    
    private func createNotify(with object: ChallengeObject) -> NotificationObject {
        return NotificationObject(
            userId: userId,
            category: .challenge,
            title: object.title,
            desc: "도전과제가 완료되었습니다! 도전을 완료하고 물방울을 획득해주세요.",
            updateAt: Date(),
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
