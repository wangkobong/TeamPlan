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
    
    // public
    var dto: HomeDataDTO
    let challengeSC: ChallengeService
    
    // private
    private let userId: String
    private let userName: String
    private var projectList: [ProjectObject] = []
    
    private let userCD: UserServicesCoredata
    private let statCD: StatisticsServicesCoredata
    private let projectCD: ProjectServicesCoredata
    private let projectMock: ProjectMock
    
    // MARK: - Initializer
    init(with userId: String, and userName: String) {
        self.userId = userId
        self.userName = userName
        self.dto = HomeDataDTO(with: userName)
        self.userCD = UserServicesCoredata()
        self.statCD = StatisticsServicesCoredata()
        self.projectCD = ProjectServicesCoredata()
        self.projectMock = ProjectMock()
        self.challengeSC = ChallengeService(with: userId)
    }
    
    // MARK: - PrepareDTO
    func prepareService() async -> Bool {
        let dto: HomeDataDTO
        
        do {
            try await prepareProperties()
            
            async let isPharseReady = getPhrase()
            async let isStatDataReady = getStat()
            async let isMyChallengeReady = getMyChallenge()
            async let isChallengeReady = getChallenge()
            async let isProjectReady = getProjectListAndDTO()
            
            let results = await [isPharseReady, isStatDataReady, isMyChallengeReady, isChallengeReady, isProjectReady]
            if results.allSatisfy({$0}) {
                print("[HomeService] Successfully prepare HomeDataDTO")
                return true
            } else {
                print("[HomeService] Failed to prepare HomeDataDTO")
                return false
            }
        } catch {
            print("[HomeService] Failed to prepare challengeService")
            return false
        }
    }
    
    private func prepareProperties() async throws {
        try await challengeSC.prepareService()
    }
    
    // MARK: - UpdateDTO
    
    func updateService() async -> Bool {
        do {
            async let isStatDataReady = getStat()
            async let isProjectReady = getProjectListAndDTO()
            
            let results = await [isStatDataReady, isProjectReady]
            if results.allSatisfy({$0}) {
                print("[HomeService] Successfully update HomeDataDTO")
                return true
            } else {
                print("[HomeService] Failed to update HomeDataDTO")
                return false
            }
        }
    }
    
    // MARK: - Pharse
    
    private func getPhrase() async -> Bool {
        if let phrase = UserPhrase().stringAry.randomElement() {
            dto.phrase = phrase
            return true
        } else {
            print("[HomeService] Failed to get phrase")
            return false
        }
    }
    
    // MARK: - Statistics
    
    func getStat() async -> Bool {
        do {
            let statObject = try statCD.getObject(with: userId)
            dto.statData = StatDTO(with: statObject)
            return true
        } catch {
            print("[Hom eService] Failed to get StatData: \(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - Challenge
    
    // MyChallenge
    private func getMyChallenge() async -> Bool {
        do {
            let myChallenges = try challengeSC.getMyChallenges()
            dto.myChallenges = myChallenges
            return true
        } catch {
            print("[HomeService] Failed to get myChallenge from challengeService: \(error.localizedDescription)")
            return false
        }
    }
    
    // Challenge
    private func getChallenge() async -> Bool {
        do {
            let challenges = try challengeSC.getChallenges()
            dto.challenges = challenges
            return true
        } catch {
            print("[HomeService] Failed to get TotalChallenge from challengeService: \(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - Project
    
    private func getProjectListAndDTO() async -> Bool {
        do {
            let projectList = try projectCD.getObjects(with: userId)
            let sortedProjects = projectList.sorted { $0.deadline < $1.deadline }.prefix(3).map { $0 }
            let dtoList = try sortedProjects.map { try projectCD.convertObjectToDTO(with: $0) }
            
            dto.projects = projectList
            dto.projectsDTO = dtoList
            return true
        } catch {
            print("[HomeService] Failed to get ProjectList or ProjectDTO from localStorage: \(error.localizedDescription)")
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
    var challenges: [ChallengeDTO]
    var myChallenges: [MyChallengeDTO]
    var projects: [ProjectObject]
    var projectsDTO: [ProjectHomeDTO]
    
    init(with userName: String){
        self.userName = userName
        self.phrase = "unknown"
        self.statData = StatDTO()
        self.challenges = []
        self.myChallenges = []
        self.projects = []
        self.projectsDTO = []
    }
    
    init(userName: String,
         phrase: String,
         statData: StatDTO,
         challenges: [ChallengeDTO],
         myChallenges: [MyChallengeDTO],
         projects: [ProjectObject],
         projectsDTO: [ProjectHomeDTO]
    ) {
        self.userName = userName
        self.phrase = phrase
        self.statData = statData
        self.challenges = challenges
        self.myChallenges = myChallenges
        self.projects = projects
        self.projectsDTO = projectsDTO
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
