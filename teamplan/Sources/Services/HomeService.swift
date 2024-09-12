//
//  HomeService.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/08/25.
//  Copyright © 2023 team1os. All rights reserved.
//

import CoreData
import Foundation

final class HomeService {
    
    //MARK: Properties
    
    // public
    var dto: HomeDataDTO
    
    // private
    private let userId: String
    private let userName: String
    private var projectList: [ProjectObject] = []
    
    private let userCD = UserServicesCoredata()
    private let statCD = StatisticsServicesCoredata()
    private let projectCD = ProjectServicesCoredata()
    private let challengeCD = ChallengeServicesCoredata()
    private let localStorageManager: LocalStorageManager
    
    init(with userId: String, and userName: String) {
        self.userId = userId
        self.userName = userName
        self.dto = HomeDataDTO(with: userName)
        self.localStorageManager = LocalStorageManager.shared
    }
    
    // MARK: - Executor
    
    func prepareExecutor() -> Bool {
        let context = localStorageManager.context
        var results = [Bool]()
        
        context.performAndWait {
            let isPharseReady = getPhrase()
            let isStatDataReady = getStatData(with: context)
            let isMyChallengeReady = getMyChallenges(with: context)
            let isProjectReady = getProjects(with: context)
            results =  [isPharseReady, isStatDataReady, isMyChallengeReady, isProjectReady]
        }
        if results.allSatisfy({$0}) {
            return true
        } else {
            print("[HomeService] Failed to prepare HomeDataDTO")
            return false
        }
    }
    
    func updateExecutor() -> Bool {
        let context = localStorageManager.context
        var results = [Bool]()
        
        context.performAndWait{
            let isStatDataReady = getStatData(with: context)
            let isMyChallengeReady = getMyChallenges(with: context)
            let isProjectReady = getProjects(with: context)
            results =  [isStatDataReady, isMyChallengeReady, isProjectReady]
        }
        if results.allSatisfy({$0}) {
            return true
        } else {
            print("[HomeService] Failed to update HomeDataDTO")
            return false
        }
    }
    
    // MARK: - Pharse
    
    private func getPhrase() -> Bool {
        if let phrase = UserPhrase().stringAry.randomElement() {
            dto.phrase = phrase
            return true
        } else {
            print("[HomeService] Failed to get phrase")
            return false
        }
    }
    
    // MARK: - Statistics
    
    private func getStatData(with context: NSManagedObjectContext) -> Bool {
        do {
            if try statCD.getObject(context: context, userId: userId) {
                let object = statCD.object
                self.dto.statData = StatDTO(with: object)
                return true
            } else {
                print("[HomeService] Error detected while fetch StatData from storage")
                return false
            }
        } catch {
            print("[HomeService] Error detected while converting Stat entity")
            return false
        }
        
    }
    
    // MARK: - Challenge
    
    private func getMyChallenges(with context: NSManagedObjectContext) -> Bool {
        do {
            if try challengeCD.getMyObjects(context: context, userId: userId) {
                let myChallenges = challengeCD.objects
                
                if myChallenges.isEmpty {
                    dto.myChallenges = []
                } else {
                    dto.myChallenges = myChallenges.map{ MyChallengeDTO(object: $0, progress: 0) }
                }
                return true
                
            } else {
                print("[HomeService] Error detected while fetch ChallengeData from storage")
                return false
            }
        } catch {
            print("[HomeService] Error detected while converting Challenge entity")
            return false
        }
    }
    
    // MARK: - Project
    
    private func getProjects(with context: NSManagedObjectContext) -> Bool {
        if projectCD.getSortedDTOs(context: context, with: userId) {
            dto.projectsDTOs = projectCD.sortedDTO
            return true
        } else {
            print("[HomeService] Error detected while fetch ProjectData from storage")
            return false
        }
    }
}

//MARK: DTO

struct HomeDataDTO {
    let id = UUID().uuidString
    var userName: String
    var phrase: String
    var statData: StatDTO
    var myChallenges: [MyChallengeDTO]
    var projectsDTOs: [ProjectHomeDTO]
    
    init(with userName: String){
        self.userName = userName
        self.phrase = "unknown"
        self.statData = StatDTO()
        self.myChallenges = []
        self.projectsDTOs = []
    }
    
    init(userName: String,
         phrase: String,
         statData: StatDTO,
         myChallenges: [MyChallengeDTO],
         projectsDTO: [ProjectHomeDTO]
    ) {
        self.userName = userName
        self.phrase = phrase
        self.statData = statData
        self.myChallenges = myChallenges
        self.projectsDTOs = projectsDTO
    }
}

struct UserPhrase {
    let stringAry = [
        "오늘의 목표를 향해 달려볼까요?",
        "훗, 어딜 보시는거죠? 거긴 제 잔상입니다만!",
        "폭탄맨 버려? 동료 버려? 어시스턴트 버려?!",
        "역시 자네야!",
        "마감을 지킨다면 유혈사태는 일어나지 않을것입니다"
    ]
}
