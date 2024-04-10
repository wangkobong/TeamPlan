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
    private var syncServerWithLocal: SyncServerWithLocal
    private let authGoogle = AuthGoogleService()
    
    private var userId: String = ""
    private var completedChallenges: [ChallengeObject] = []
    
    init(userId: String) {
        self.userId = userId
        self.syncServerWithLocal = SyncServerWithLocal(with: userId)
    }
    
    func prepareService() async throws {
        let challenges = try await challengeCD.getObjects(with: userId)
        completedChallenges = challenges.filter { $0.status == true }
    }
    
    func getMypageDTO() throws -> MypageDTO {
        let user = try userCD.getObject(with: userId)
        let stat = try statCD.getObject(with: userId)
        return MypageDTO(
            nickName: user.name,
            protected: stat.totalFinishedProjects,
            destroyed: stat.totalFailedProjects,
            completedProjects: stat.totalFinishedProjects,
            completedChallenges: completedChallenges.count,
            completedTodos: stat.totalFinishedTodos
        )
    }
    
    func logout() throws {
        try authGoogle.logout()
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
    let completedProjects: Int
    let completedChallenges: Int
    let completedTodos : Int
    
    init(nickName: String, 
         protected: Int,
         destroyed: Int,
         completedProjects: Int,
         completedChallenges: Int,
         completedTodos: Int)
    {
        self.nickName = nickName
        self.protected = protected
        self.destroyed = destroyed
        self.completedProjects = completedProjects
        self.completedChallenges = completedChallenges
        self.completedTodos = completedTodos
    }
}
