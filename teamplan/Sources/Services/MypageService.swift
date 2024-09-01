//
//  MypageService.swift
//  teamplan
//
//  Created by 크로스벨 on 4/9/24.
//  Copyright © 2024 team1os. All rights reserved.
//

import CoreData
import Foundation
import FirebaseAuth

final class MypageService {
    
    // shared
    var mypageDTO: MypageDTO
    
    // private
    private let userCD: UserServicesCoredata
    private let statCD: StatisticsServicesCoredata
    private let challengeCD: ChallengeServicesCoredata
    
    private var userId: String
    private var completedChallenges: Int
    private let context: LocalStorageManager
    
    init(userId: String) {
        self.userCD = UserServicesCoredata()
        self.statCD = StatisticsServicesCoredata()
        self.challengeCD = ChallengeServicesCoredata()
        
        self.userId = userId
        self.completedChallenges = 0
        self.context = LocalStorageManager.shared
        self.mypageDTO = MypageDTO()
    }
    
    func prepareService() -> Bool {
        do {
            let context = self.context.context
            
            try context.performAndWait{
                self.completedChallenges = try challengeCD.countCompleteObjects(context: context, userId: userId)
                let isUserDataFetched = try userCD.getObject(context: context, userId: userId)
                let isStatDataFetched = try statCD.getObject(context: context, userId: userId)
                
                if isUserDataFetched && isStatDataFetched {
                    let user = userCD.object
                    let stat = statCD.object
                    self.mypageDTO = MypageDTO(
                        nickName: user.name,
                        protected: stat.totalFinishedProjects,
                        destroyed: stat.totalFailedProjects,
                        serviceTerm: stat.term,
                        completedProjects: stat.totalFinishedProjects,
                        completedChallenges: completedChallenges,
                        completedTodos: stat.totalFinishedTodos
                    )
                }
            }
            return true
        } catch {
            print("[MypageService] Failed to prepare service data")
            return false
        }
    }
    
    func logout() async -> Bool {
        return true
        /*
        if await loginService.logoutUser() {
            print("[MypageService] Successfully proceed logout")
            return true
        } else {
            return false
        }
        */
    }
    
    func withdraw() async -> Bool {
        return true
        /* Delete every user data at local & server
        if await deleteSync.deleteExecutor() {
            
            if await loginService.withdrawUser() {
                print("[MypageService] Successfully proceed withdraw")
                return true
            } else {
               return false
            }
        } else {
            return false
        }
        */
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
    case logout = "로그아웃"
    case withdraw = "회원탈퇴"
    case version = "앱버젼"
}
