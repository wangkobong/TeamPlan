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
    let userDefaultManager = UserDefaultManager.loadWith(key: "user")
    lazy var identifier = userDefaultManager?.identifier
    lazy var homeService = HomeService(identifier: self.identifier ?? "")
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        self.addSubscribers()
        Task {
            await self.getUserName()
        }
        configureData()
    }
    
    private func addSubscribers() {
        /*
        challengeService.$myChallenges
            .sink { [weak self] challenges in
                self?.myChallenges = challenges
            }
            .store(in: &cancellables)
         */
        
        homeService.challenge.$myChallenges
            .sink { [weak self] myChallenges in
                print("myChallenges: \(myChallenges)")
            }
            .store(in: &cancellables)
        
        homeService.challenge.$statistics
            .sink { [weak self] statistics in
                print("statistics: \(String(describing: statistics))")
            }
            .store(in: &cancellables)
        
        homeService.challenge.$challengeArray
            .sink { [weak self] challengeArray in
                print("challengeArray: \(String(describing: challengeArray))")
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
}
