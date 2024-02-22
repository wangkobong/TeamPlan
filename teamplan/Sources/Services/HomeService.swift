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
    // MARK: - Properties
    //===============================
    // for service
    private let userCD = UserServicesCoredata()
    private let projectCD = ProjectServicesCoredata()
    private let phrase = UserPhrase()
    private let userId: String

    // for log
    private let util = Utilities()
    private let location = "HomeService"
    
    // shared
    let challenge: ChallengeService
    
    //===============================
    // MARK: - Initializer
    //===============================
    /// 사용자 ID를 기반으로 `HomeService` 및 `ChallengeService` 인스턴스를 생성합니다.
    /// - Parameter userId: 사용자 ID입니다.
    init(with userId: String){
        self.userId = userId
        self.challenge = ChallengeService(with: userId)
    }
    
    /// `HomeService`에서 사용되는 `ChallengeService` 인스턴스의 필수적인 추가 초기화 작업을 수행합니다,
    /// - Throws: 서비스 초기화 중 예상치 못한 오류가 발생한 경우 `HomeServiceError.UnexpectedInitError`가 발생합니다.
    func readyService() throws {
        do {
            try self.challenge.readyService()
            util.log(.info, location, "Service Ready", userId)
        } catch {
            print("(Service) Error while Init in HomeService : \(error)")
            throw HomeServiceError.UnexpectedInitError
        }
    }
    
    //===============================
    // MARK: - Generate Sentence
    //===============================
    // MARK: - Generate Sentence
    /// 랜덤한 문장을 생성하여 반환합니다.
    /// - Returns: 생성된 문장입니다.
    /// - Throws: 문장 생성에 실패한 경우 `HomeServiceError.InternalError`가 발생합니다.
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
    // MARK: - Get ProjectCard
    /// 사용자의 목표(project) 조회 후, 마감일이 가장 가까운 3개를 내림차순으로 정렬하여 반환합니다.
    /// - Returns: `[ProjectCardDTO]` 목표(Project) 정보들 중, Card에 표현될 정보만 포함되어 있습니다.
    /// - Throws: 조회 중 예상치 못한 오류가 발생한 경우 `HomeServiceError.UnexpectedProjectCardGetError`가 발생합니다.
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
    /// 사용자의 '나의 도전과제' 목록을 조회합니다'
    /// - Returns: 조회된 '나의 도전과제' 정보를 '[MyChallengeDTO]' 형태로 반환합니다. 단, 사용자가 '나의 도전과제' 를 지정하지 않은경우 '[]' 가 반환됩니다.
    /// - Throws: 챌린지 조회 중 오류가 발생한 경우 해당 오류를 던집니다.
    func getMyChallenge() throws -> [MyChallengeDTO] {
        challenge.getMyChallenges()
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
