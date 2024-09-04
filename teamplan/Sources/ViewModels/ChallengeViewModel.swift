//
//  MyChallengeViewModel.swift
//  teamplan
//
//  Created by sungyeon on 2023/12/28.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation
import Combine

final class ChallengeViewModel: ObservableObject {
    
    //MARK: Properties

    @Published var challengeList: [ChallengeDTO] = []
    @Published var myChallenges: [MyChallengeDTO] = []
    @Published var isViewModelReady: Bool = false
    @Published var isRedirectNeed: Bool = false
    
    private let userId: String
    private let service: ChallengeService
    private var cancellables = Set<AnyCancellable>()
    
    //MARK: Initialize
    
    init() {
        let volt = VoltManager.shared
        if let identifier = volt.getUserId() {
            self.userId = identifier
            
        // UserDefault: Exception Handling
        } else {
            print("[HomeViewModel] ViewModel Initialize Failed")
            self.userId = "unknown"
        }
        self.service = ChallengeService(with: self.userId)
        addSubscribers()
        Task { await self.prepareData() }
    }
    
    private func addSubscribers() {
        service.$myChallenges
            .receive(on: DispatchQueue.main)
            .sink { [weak self] myChallenges in
                DispatchQueue.main.async {
                    self?.myChallenges = myChallenges
                }
            }
            .store(in: &cancellables)
        
        service.$challengesDTO
            .receive(on: DispatchQueue.main)
            .sink { [weak self] challengeList in
                DispatchQueue.main.async {
                    self?.challengeList = challengeList.sorted(by: { $0.challengeId < $1.challengeId })
                }
            }
            .store(in: &cancellables)
    }
    
    private func prepareData() async {
        if self.userId == "unknown" {
            print("[ChallengeViewModel] Unknown UserId detected!")
            self.isRedirectNeed = true
        }
        
        if self.service.prepareExecutor() {
            self.isViewModelReady = true
            
        } else {
            print("[ChallengeViewModel] Failed to Initialize ViewModel")
            self.isRedirectNeed = true
        }
    }
}

//MARK: Function

extension ChallengeViewModel {
    
    func setMyChallenge(with challengeId: Int) async -> Bool {
        if service.setMyChallenges(with: challengeId) {
            return true
            
        } else {
            print("[ChallengeViewModel] Failed to set myChallenge")
            return false
        }
    }
    
    func disableMtChallenge(with challengeId: Int) async -> Bool {
        if service.disableMyChallenge(with: challengeId) {
            return true
            
        } else {
            print("[ChallengeViewModel] Failed to disable myChallenge")
            return false
        }
    }
    
    func rewardMyChallenge(with challengeId: Int) async -> Bool {
        if service.rewardMyChallenge(with: challengeId) {
            return true
            
        } else {
            print("[ChallengeViewModel] Failed to reward myChallenge")
            return false
        }
    }
}
