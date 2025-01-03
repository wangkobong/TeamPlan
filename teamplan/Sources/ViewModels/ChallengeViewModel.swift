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
    @Published var isRedirectNeed: Bool = false
    
    private let userId: String
    private let service: ChallengeService
    private var cancellables = Set<AnyCancellable>()
    
    //MARK: Initialize
    
    init() {
        let volt = VoltManager.shared
        if let identifier = volt.getUserId() {
            self.userId = identifier
        } else {
            print("[ChallengeViewModel] ViewModel Initialize Failed")
            self.userId = "unknown"
        }
        self.service = ChallengeService(with: self.userId)
    }
    
    func prepareData() async -> Bool {
        
        if await service.prepareExecutor() {
            await updateProperties()
            return true
        } else {
            print("[ChallengeViewModel] Failed to Initialize ViewModel")
            self.isRedirectNeed = true
            return false
        }
    }
}

//MARK: Function

extension ChallengeViewModel {
    
    func setMyChallenge(with challengeId: Int) async -> Bool {
        if await service.setMyChallenges(with: challengeId) {
            await updateProperties()
            return false
        } else {
            print("[ChallengeViewModel] Failed to set myChallenge")
            return false
        }
    }
    
    func disableMtChallenge(with challengeId: Int) async -> Bool {
        if await service.disableMyChallenge(with: challengeId) {
            await updateProperties()
            return false
        } else {
            print("[ChallengeViewModel] Failed to disable myChallenge")
            return false
        }
    }
    
    func rewardMyChallenge(with challengeId: Int) async -> Bool {
        if await service.rewardMyChallenge(with: challengeId) {
            await updateProperties()
            return false
        } else {
            print("[ChallengeViewModel] Failed to reward myChallenge")
            return false
        }
    }
    
    @MainActor
    private func updateProperties() async {
        self.myChallenges = service.myChallenges
        self.challengeList = service.challengesDTO
    }
}
