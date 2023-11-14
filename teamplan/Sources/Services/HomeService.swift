//
//  HomeService.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/08/25.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation

final class HomeService {
    
    //===============================
    // MARK: - Parameter Setting
    //===============================
    let userCD = UserServicesCoredata()
    let projectCD = ProjectServicesCoredata()
    let challenge: ChallengeService
    let phrase = UserPhrase()
    
    let identifier: String
    var statistics: StatisticsDTO?
    
    //===============================
    // MARK: - Initializer
    //===============================
    init(identifier: String){
        self.identifier = identifier
        self.challenge = ChallengeService(identifier)
    }
    
    func readyService() throws {
        do {
            try self.challenge.loadStatistics()
            try self.challenge.loadChallenges()
            try self.challenge.loadMyChallenges()
        } catch {
            print("(Service) Error while Init in HomeService : \(error)")
            throw HomeServiceError.UnexpectedInitError
        }
    }
    
    //===============================
    // MARK: - Generate Sentence
    //===============================
    func getSentences() throws -> String {
        if let phrase = self.phrase.stringAry.randomElement() {
            return phrase
        } else {
            print("(Service) Error while Generate Sentence in HomeService")
            throw HomeServiceError.InternalError
        }
    }
    
    //===============================
    // MARK: - get ProjectCard
    //===============================
    func getProjectCard() throws -> [ProjectCardDTO] {
        do {
            // Get All Projects
            let requestProjects = try self.projectCD.getProjects(from: self.identifier)
            
            return requestProjects
            // Sorted by DeadLine
                .sorted { $0.proj_deadline > $1.proj_deadline }
            // Set Top3
                .prefix(3)
            // Convert to ProjectCard
                .map { ProjectCardDTO(from: $0) }
        } catch {
            print("(Service) Error get ProjectCard in HomeService : \(error)")
            throw HomeServiceError.UnexpectedProjectCardGetError
        }
    }
}

//===============================
// MARK: - MyChallenge
//===============================
extension HomeService{
    // Get MyChallenge
    func getMyChallenge() throws -> [MyChallengeDTO] {
        try challenge.getMyChallenges()
    }
    // Disable MyChallenge
    func disableMyChallenge(from challengeId: Int) async throws {
        try await challenge.disableMyChallenge(from: challengeId)
    }
    // Reward MyChallenge
    func rewardMyChallenge(from challengeId: Int) async throws -> ChallengeRewardDTO {
        try await challenge.rewardMyChallenge(from: challengeId)
    }
}

//===============================
// MARK: - Exception
//===============================
enum HomeServiceError: LocalizedError {
    case UnexpectedInitError
    case UnexpectedSentenceGenerateError
    case UnexpectedProjectCardGetError
    case InternalError
    
    var errorDescription: String?{
        switch self {
        case .UnexpectedInitError:
            return "Service: There was an unexpected error while Initialize 'HomeService'"
        case .UnexpectedSentenceGenerateError:
            return "Service: There was an unexpected error while Generate Sentence in 'HomeService'"
        case .UnexpectedProjectCardGetError:
            return "Service: There was an unexpected error while Get 'ProjectCard' in 'HomeService'"
        case .InternalError:
            return "Service: Internal Error Occurred while processing 'HomeService'"
        }
    }
}
