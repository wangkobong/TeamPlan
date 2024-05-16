//
//  MypageService.swift
//  teamplan
//
//  Created by 크로스벨 on 4/9/24.
//  Copyright © 2024 team1os. All rights reserved.
//

import Foundation

final class MypageService {
    
    private let userCD = UserServicesCoredata()
    private let statCD = StatisticsServicesCoredata()
    private let challengeCD = ChallengeServicesCoredata()
    private let loginService = LoginService()
    private var syncServerWithLocal: SyncServerWithLocal
    
    private var userId: String
    private var completedChallenges: Int
    
    init(userId: String) {
        self.userId = userId
        self.completedChallenges = 0
        self.syncServerWithLocal = SyncServerWithLocal(with: userId)
    }
    
    func prepareService() async throws {
        self.completedChallenges = try await challengeCD.getCompleteObjects(with: self.userId)
    }
    
    func getMypageDTO() throws -> MypageDTO {
        let user = try userCD.getObject(with: userId)
        let stat = try statCD.getObject(with: userId)
        return MypageDTO(
            nickName: user.name,
            protected: stat.totalFinishedProjects,
            destroyed: stat.totalFailedProjects,
            serviceTerm: stat.term,
            completedProjects: stat.totalFinishedProjects,
            completedChallenges: completedChallenges,
            completedTodos: stat.totalFinishedTodos
        )
    }
    
    func logout() throws {
        loginService.logoutUser()
    }
    
    // Delete every user data at local & server
    func withdraw() async throws {
        try await syncServerWithLocal.deleteExecutor(with: userId)
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
    case guide = "가이드북"
    case logout = "로그아웃"
    case withdraw = "회원탈퇴"
    case version = "앱버젼"
}
