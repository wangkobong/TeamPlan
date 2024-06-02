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
//            self.userName = userName
            
        // UserDefault: Exception Handling
        } else {
            print("[HomeViewModel] ViewModel Initialize Failed")
            self.identifier = "unknown"
            self.isLoginRedirectNeed = true
        }
        
        // Initialize Properties with Identifier
        self.homeSC = HomeService(with: self.identifier)
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
}

// MARK: Data Change Detector
// TODO: Need To Update with using 'userData' version
extension HomeViewModel {
    
    private func addSubscribers() {

    }
    
    func tryChallenge(with challengeId: Int) {
        do {
            print("challengeId: \(challengeId)")
            try homeSC.challengeSC.setMyChallenges(with: challengeId)
        } catch let error {
            // Handle the error here
            print("[HomeViewModel] Failed to Set Challenge: \(error.localizedDescription)")
        }
    }
    
    func quitChallenge(with challengeId: Int) {
        do {
            try homeSC.challengeSC.disableMyChallenge(with: challengeId)
        } catch let error {
            // Handle the error here
            print("[HomeViewModel] Failed to Disable Challenge: \(error.localizedDescription)")
        }
    }
}
