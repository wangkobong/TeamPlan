//
//  MypageService.swift
//  teamplan
//
//  Created by 크로스벨 on 4/9/24.
//  Copyright © 2024 team1os. All rights reserved.
//

import CoreData
import Foundation

final class MypageService {
    
    // shared
    var mypageDTO: MypageDTO
    
    // private
    private let userCD: UserServicesCoredata
    private let statCD: StatisticsServicesCoredata
    private let challengeCD: ChallengeServicesCoredata
    
    private let mockGenerator: MockGenerator
    private let storageManager: LocalStorageManager
    
    private var userId: String
    private var completedChallenges: Int
    private var userData: UserObject
    private var statData: StatisticsObject
    
    private lazy var eraseSC: EraseService = {
        return EraseService(userId: userId)
    }()
    
    init(userId: String) {
        self.userCD = UserServicesCoredata()
        self.statCD = StatisticsServicesCoredata()
        self.challengeCD = ChallengeServicesCoredata()
        
        self.mockGenerator = MockGenerator(userId: userId)
        self.storageManager = LocalStorageManager.shared
        
        self.mypageDTO = MypageDTO()
        
        self.userId = userId
        self.completedChallenges = 0
        self.userData = UserObject()
        self.statData = StatisticsObject()
    }
    
    //MARK: Prepare properties
    
    func prepareService() -> Bool {
        var results = [Bool]()
        let context = self.storageManager.context
        
        context.performAndWait {
            results = [
                fetchUserData(context),
                fetchStatData(context),
                fetchChallengeCount(context)
            ]
        }
        
        if results.allSatisfy({$0}) {
            self.mypageDTO = MypageDTO(
                nickName: userData.name,
                protected: statData.totalFinishedProjects,
                destroyed: statData.totalFailedProjects,
                serviceTerm: statData.term,
                completedProjects: statData.totalFinishedProjects,
                completedChallenges: completedChallenges,
                completedTodos: statData.totalFinishedTodos
            )
            return true
        } else {
            print("[MypageSC] Failed to prepare service data")
            return false
        }
    }
    
    // User
    private func fetchUserData(_ context: NSManagedObjectContext) -> Bool {
        do {
            guard try userCD.getObject(context: context, userId: userId) else {
                print("[MypageSC] Failed to convert UserData")
                return false
            }
            self.userData = userCD.object
            return true
        } catch {
            print("[MypageSC] Failed to fetch UserData from storage")
            return false
        }
    }
    
    // Stat
    private func fetchStatData(_ context: NSManagedObjectContext) -> Bool {
        do {
            guard try statCD.getObject(context: context, userId: userId) else {
                print("[MypageSC] Failed to convert StatData")
                return false
            }
            self.statData = statCD.object
            return true
        } catch {
            print("[MypageSC] Failed to fetch StatData from storage")
            return false
        }
    }
    
    // Challenge
    private func fetchChallengeCount(_ context: NSManagedObjectContext) -> Bool {
        do {
            self.completedChallenges = try challengeCD.countCompleteObjects(context: context, userId: userId)
            return true
        } catch {
            print("[MypageSC] Failed to fetch challengeCount from storage")
            return false
        }
    }
    
    //MARK: Mock Injection
    
    func mockDataInjection() async -> Bool {
        return await mockGenerator.injectMockData()
    }
    
    //MARK: Erase Data
    
    func eraseData() -> Bool {
        return eraseSC.eraseExecutor()
    }
}

struct MypageDTO {
    
    let nickName: String
    let protected: Int
    let destroyed: Int
    let serviceTerm: Int
    let completedProjects: Int
    let completedChallenges: Int
    let completedTodos : Int
    
    init(nickName: String, 
         protected: Int,
         destroyed: Int,
         serviceTerm: Int,
         completedProjects: Int,
         completedChallenges: Int,
         completedTodos: Int)
    {
        self.nickName = nickName
        self.protected = protected
        self.destroyed = destroyed
        self.serviceTerm = serviceTerm
        self.completedProjects = completedProjects
        self.completedChallenges = completedChallenges
        self.completedTodos = completedTodos
    }
    
    init() {
        self.nickName = "unknown"
        self.protected = 0
        self.destroyed = 0
        self.serviceTerm = 0
        self.completedProjects = 0
        self.completedChallenges = 0
        self.completedTodos = 0
    }
}

enum MypageMenu: String {
    case erase = "모든 데이터 삭제하기"
    case version = "앱버젼"
}
