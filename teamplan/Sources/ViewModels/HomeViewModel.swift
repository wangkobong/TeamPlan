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
    @Published var myChallenges: [ChallengeCardResDTO] = []
    
    private let homeService = HomeService(identifier: "")
    private let loginService = LoginLoadingService()
    private let challengeService = ChallengeService("")
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        self.addSubscribers()
        Task {
            await self.getUser()
        }
    }
    
    private func addSubscribers() {
        /*
        challengeService.$myChallenges
            .sink { [weak self] challenges in
                self?.myChallenges = challenges
            }
            .store(in: &cancellables)
         */
    }
    
    @MainActor
    private func getUser() async {

    }
}
