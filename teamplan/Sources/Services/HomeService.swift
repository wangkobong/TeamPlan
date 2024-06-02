//
//  HomeService.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/08/25.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation

final class HomeService {
    
    //MARK: Properties
    // private
    private let userId: String
    private let userCD: UserServicesCoredata
    private let statCD: StatisticsServicesCoredata
    private let projectCD: ProjectServicesCoredata
    
    // public
    let challengeSC: ChallengeService
    @Published var dto: HomeDataDTO = HomeDataDTO()
    
    // MARK: - Initializer
    init(with userId: String) {
            self.userId = userId
            self.userCD = UserServicesCoredata()
            self.statCD = StatisticsServicesCoredata()
            self.projectCD = ProjectServicesCoredata()
            self.challengeSC = ChallengeService(with: userId)
        }
    
    // MARK: - PrepareDTO
    func prepareService() async throws {
        do {
            try await prepareProperties()
            
            async let phrase = getPhrase()
            async let statData = getStat()
            async let myChallenges = getMyChallenge()
            async let challenges = getChallenge()
            async let projeccts = getProjectDTO()
            
            self.dto = try await HomeDataDTO(
                userName: self.userId,
                phrase: phrase,
                statData: statData,
                challenges: challenges,
                myChallenges: myChallenges,
                projects: projeccts
            )
            
        } catch {
            print("[HomeService] Failed to struct HomeDataDTO")
            self.dto = HomeDataDTO()
        }
    }
    
    private func prepareProperties() async throws {
        try await challengeSC.prepareService()
    }
    
    
    // MARK: - UserData
    // Phrase
    private func getPhrase() async throws -> String {
        if let phrase = UserPhrase().stringAry.randomElement() {
            return phrase
        } else {
            print("[HomeService] Failed to get phrase")
            return "Error"
        }
    }
    
    
    // MARK: - Statistics
    
    private func getStat() async throws -> StatChallengeDTO {
        do {
            let stat = try statCD.getObject(with: userId)
            return StatChallengeDTO(with: stat)
        } catch {
            print("[HomeService] Failed to get StatData: \(error.localizedDescription)")
            return StatChallengeDTO()
        }
    }
    
    
    // MARK: - Challenge
    // MyChallenge
    private func getMyChallenge() async throws -> [MyChallengeDTO] {
        do {
            return try challengeSC.getMyChallenges()
        } catch {
            print("[HomeService] Failed to get myChallenge from challengeService: \(error.localizedDescription)")
            return []
        }
    }
    
    // Challenge
    private func getChallenge() async throws -> [ChallengeDTO] {
        do {
            return try challengeSC.getChallenges()
        } catch {
            print("[HomeService] Failed to get TotalChallenge from challengeService: \(error.localizedDescription)")
            return []
        }
    }
    
    
    // MARK: - Project
    
    private func getProjectDTO() async throws -> [ProjectHomeDTO] {
        do {
            // Get All Projects
            let projects = try self.projectCD.getDTO(with: userId)
            let sortedProjects = projects.sorted { $0.deadline < $1.deadline }.prefix(3).map { $0 }
            // Return top 3 projects
            return sortedProjects
        } catch {
            print("[HomeService] Failed to get Project from ProjectCD: \(error.localizedDescription)")
            return []
        }
    }
}

//MARK: DTO

struct HomeDataDTO {
    let id = UUID().uuidString
    let userName: String
    let phrase: String
    let statData: StatChallengeDTO
    var challenges: [ChallengeDTO]
    var myChallenges: [MyChallengeDTO]
    var projects: [ProjectHomeDTO]
    
    init(){
        self.userName = "unknown"
        self.phrase = "unknown"
        self.statData = StatChallengeDTO()
        self.challenges = []
        self.myChallenges = []
        self.projects = []
    }
    
    init(userName: String,
         phrase: String,
         statData: StatChallengeDTO,
         challenges: [ChallengeDTO],
         myChallenges: [MyChallengeDTO],
         projects: [ProjectHomeDTO]
    ) {
        self.userName = userName
        self.phrase = phrase
        self.statData = statData
        self.challenges = challenges
        self.myChallenges = myChallenges
        self.projects = projects
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
