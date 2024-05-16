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
    
    @Published var userName: String = ""
    @Published var myChallenges: [MyChallengeDTO] = []
    @Published var challengeArray: [ChallengeObject] = []
    @Published var statistics: StatChallengeDTO?
    
    private let identifier: String
    private var cancellables = Set<AnyCancellable>()
    lazy var homeService = HomeService(with: self.identifier)
    
    init() {
        if let userDefault = UserDefaultManager.loadWith(key: UserDefaultKey.user.rawValue),
           let identifier = userDefault.identifier {
            self.identifier = identifier
        } else {
            self.identifier = "unknown"
            print("[HomeViewModel] Initialize Failed")
        }
        self.addSubscribers()
        self.loadData()
    }

    private func loadData() {
        Task {
            await self.getUserName()
            await self.configureData()
        }
    }
    
    @MainActor
    private func getUserName() {
        if let userDefault = UserDefaultManager.loadWith(key: UserDefaultKey.user.rawValue),
           let userName = userDefault.userName {
            self.userName = userName
        } else {
            self.userName = "unknown"
            print("[HomeViewModel] UserDefault Data load Failed")
        }
    }
    
    func configureData() async {
        do {
            try await homeService.readyService()
        } catch let error {
            print("[HomeViewModel] Failed to Initialize Service: \(error.localizedDescription)")
        }
    }
}

// MARK: Challenge

extension HomeViewModel {
    
    private func addSubscribers() {
        
        homeService.challenge.$myChallenges
            .receive(on: DispatchQueue.main)
            .sink { [weak self] myChallenges in
                self?.myChallenges = myChallenges
            }
            .store(in: &cancellables)
        
        homeService.challenge.$statDTO
            .sink { [weak self] statistics in
                self?.statistics = statistics
            }
            .store(in: &cancellables)
        
        homeService.challenge.$challengeArray
            .sink { [weak self] challengeArray in
                self?.challengeArray = challengeArray
            }
            .store(in: &cancellables)
    }
    
    func tryChallenge(with challengeId: Int) {
        do {
            print(challengeId)
            try homeService.challenge.setMyChallenges(with: challengeId)
        } catch let error {
            // Handle the error here
            print("[HomeViewModel] Failed to Set Challenge: \(error.localizedDescription)")
        }
    }
    
    func quitChallenge(with challengeId: Int) {
        do {
            try homeService.challenge.disableMyChallenge(with: challengeId)
        } catch let error {
            // Handle the error here
            print("[HomeViewModel] Failed to Disable Challenge: \(error.localizedDescription)")
        }
    }
}
