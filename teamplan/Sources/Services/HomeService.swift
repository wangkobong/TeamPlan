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
    
    let userId: String
    
    //===============================
    // MARK: - Initializer
    //===============================
    init(with userId: String){
        self.userId = userId
        self.challenge = ChallengeService(with: userId)
    }
    
    func readyService() throws {
        do {
            try self.challenge.readyService()
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
            let projects = try self.projectCD.getProjectCards(by: userId)
            // Sort by deadline
            let sortedProjects = projects.sorted { $0.deadline < $1.deadline }
            // Return top 3 projects
            return Array(sortedProjects.prefix(upTo: 3))
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
    func disableMyChallenge(from challengeId: Int) throws {
        try challenge.disableMyChallenge(with: challengeId)
    }
    // Reward MyChallenge
    func rewardMyChallenge(from challengeId: Int) throws -> ChallengeRewardDTO {
        try challenge.rewardMyChallenge(with: challengeId)
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
