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
    let identifier: String
    lazy var homeService = HomeService(with: self.identifier)
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        let userDefaultManager = UserDefaultManager.loadWith(key: "user")
        let identifier = userDefaultManager?.identifier
        self.identifier = identifier ?? ""
        self.addSubscribers()
        Task {
            await self.getUserName()
        }
        configureData()
    }
    
    private func addSubscribers() {
        
        homeService.challenge.$myChallenges
            .receive(on: DispatchQueue.main)
            .sink { [weak self] myChallenges in
                print("myChallenges: \(myChallenges)")
                self?.myChallenges = myChallenges
            }
            .store(in: &cancellables)
        
        homeService.challenge.$statDTO
            .sink { [weak self] statistics in
                print("statistics: \(String(describing: statistics))")
                self?.statistics = statistics
            }
            .store(in: &cancellables)
        
        homeService.challenge.$challengeArray
            .sink { [weak self] challengeArray in
                self?.challengeArray = challengeArray
            }
            .store(in: &cancellables)
    }
    
    @MainActor
    private func getUserName() async {
        let userDefaultManager = UserDefaultManager.loadWith(key: "user")
        self.userName = userDefaultManager?.userName ?? "Unkown"
    }
    
    func configureData() {
        do {
            try homeService.readyService()
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    func tryChallenge(with challengeId: Int) {
        do {
            try homeService.challenge.setMyChallenges(with: challengeId)
        } catch let error {
            // Handle the error here
            print("Error: \(error)")
        }
    }
    
    func quitChallenge(with challengeId: Int) {
        do {
            try homeService.challenge.disableMyChallenge(with: challengeId)
        } catch let error {
            // Handle the error here
            print("Error: \(error)")
        }
    }
    
}
