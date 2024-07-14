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

    @Published var challengeList: [ChallengeDTO]
    @Published var myChallenges: [MyChallengeDTO]
    @Published var isViewModelReady: Bool = false
    @Published var isRedirectNeed: Bool = false
    
    private let userId: String
    private let service: ChallengeService
    
    //MARK: Initialize
    
    init() {
        if let userDefault = UserDefaultManager.loadWith(),
           let identifier = userDefault.identifier,
           let userName = userDefault.userName {
            self.userId = identifier
            
        // UserDefault: Exception Handling
        } else {
            print("[HomeViewModel] ViewModel Initialize Failed")
            self.userId = "unknown"
        }
        
        self.service = ChallengeService(with: self.userId)
        self.challengeList = []
        self.myChallenges = []
        Task { await self.prepareData() }
    }
    
    private func prepareData() async {
        if self.userId == "unknown" {
            print("[ChallengeViewModel] Unknown UserId detected!")
            self.isRedirectNeed = true
        }
        
        if self.service.prepareExecutor() {
            await updateList()
            self.isViewModelReady = true
            print("[ChallengeViewModel] Successfully prepared viewModel: \(self.myChallenges)")
            
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
            await updateList()
            print("[ChallengeViewModel] Successfully set myChallenge")
            return true
            
        } else {
            print("[ChallengeViewModel] Failed to set myChallenge")
            return false
        }
    }
    
    func disableMtChallenge(with challengeId: Int) async -> Bool {
        if service.disableMyChallenge(with: challengeId) {
            await updateList()
            print("[ChallengeViewModel] Successfully disable myChallenge")
            return true
            
        } else {
            print("[ChallengeViewModel] Failed to disable myChallenge")
            return false
        }
    }
    
    func rewardMyChallenge(with challengeId: Int) async -> Bool {
        if service.rewardMyChallenge(with: challengeId) {
            await updateList()
            print("[ChallengeViewModel] Successfully reward myChallenge")
            return true
            
        } else {
            print("[ChallengeViewModel] Failed to reward myChallenge")
            return false
        }
    }
    
    @MainActor
    private func updateList() {
        self.challengeList = service.challengesDTO
        self.myChallenges = service.myChallenges
    }
}
