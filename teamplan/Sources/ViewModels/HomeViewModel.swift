//
//  HomeViewModel.swift
//  teamplan
//
//  Created by sungyeon kim on 2023/10/10.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation
import Combine

final class HomeViewModel: ObservableObject {
    
    //MARK: Properties
    
    // Updated
    @Published var userData: HomeDataDTO
    @Published var isLoginRedirectNeed: Bool = false    // activated when data load fails: logout & redirect to loginView
    @Published var isViewModelReady: Bool = false       // activated when data complete: progress to homeView
    
    private let identifier: String
    private let userName: String
    private var cancellables = Set<AnyCancellable>()
    private let homeSC: HomeService

    //MARK: Initialize

    @MainActor
    init() {
        // UserDefault: Load Data
        if let userDefault = UserDefaultManager.loadWith(key: UserDefaultKey.user.rawValue),
           let identifier = userDefault.identifier,
           let userName = userDefault.userName {
            self.identifier = identifier
            self.userName = userName
            
        // UserDefault: Exception Handling
        } else {
            print("[HomeViewModel] ViewModel Initialize Failed")
            self.identifier = "unknown"
            self.userName = "unknown"
            self.isLoginRedirectNeed = true
        }
        
        // Initialize Properties with Identifier
        self.homeSC = HomeService(with: identifier, and: userName)
        self.userData = HomeDataDTO()
        
        self.prepareData()
        self.addSubscribers()
    }

    @MainActor
    private func prepareData() {
        Task {
            do {
                try await homeSC.prepareService()
                homeSC.$dto
                    .receive(on: DispatchQueue.main)
                    .sink { [weak self] userData in
                        self?.userData = userData
                    }
                    .store(in: &cancellables)

                self.isViewModelReady = true
                print("[HomeViewModel] Successfully prepare viewModel")
                
            } catch {
                print("[HomeViewModel] Failed to Initialize HomeService: \(error.localizedDescription)")
                self.isLoginRedirectNeed = true
            }
        }
    }
    
    func updateStatData() {
        Task{
            do {
                try await self.userData.statData = homeSC.getStat()
            } catch let error  {
                // Handle the error here
                print("[HomeViewModel] Failed to Update StatData: \(error.localizedDescription)")
            }
        }
    }
    
    func getChallengeProgress(with type: ChallengeType) -> Int {
        switch type {
        case .onboarding:
            return 0
        case .serviceTerm:
            return userData.statData.term
        case .waterDrop:
            return userData.statData.drop
        case .projectAlert:
            return userData.statData.totalAlertedProjects
        case .projectFinish:
            return userData.statData.totalFailedProjects
        case .totalTodo:
            return userData.statData.totalRegistedTodos
        default:
            return -1
        }
    }
}

// MARK: Data Change Detector
// TODO: Need To Update with using 'userData' version
extension HomeViewModel {
    
    private func addSubscribers() {

    }
    
    func tryChallenge(with challengeId: Int) {
        Task{
            do {
                try await homeSC.challengeSC.setMyChallenges(with: challengeId)
                await updateDTO()
                
            } catch let error {
                // Handle the error here
                print("[HomeViewModel] Failed to Set Challenge: \(error.localizedDescription)")
            }
        }
    }
    
    func quitChallenge(with challengeId: Int) {
        Task {
            do {
                try await homeSC.challengeSC.disableMyChallenge(with: challengeId)
                await updateDTO()
                
            } catch let error {
                // Handle the error here
                print("[HomeViewModel] Failed to Disable Challenge: \(error.localizedDescription)")
            }
        }
    }
    
    func completeChallenge(with challengeId: Int) {
        Task {
            do {
                try await homeSC.challengeSC.rewardMyChallenge(with: challengeId)
                await updateDTO()
                
            } catch let error {
                // Handle the error here
                print("[HomeViewModel] Failed to Disable Challenge: \(error.localizedDescription)")
            }
        }
    }
    
    private func updateDTO() async {
        self.userData.myChallenges = homeSC.challengeSC.myChallenges
        self.userData.challenges = homeSC.challengeSC.challengesDTO
        self.userData.statData = homeSC.challengeSC.statDTO
    }
}
