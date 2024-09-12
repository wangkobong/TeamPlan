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
        //addSubscribers()
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
    
    /*
     // 주석화 사유
     // 1. 해당 코드 사용을 위해 service 레이어 변수의 @Published 선언이 필요
     //   * 데이터의 변경이 잦은 service 레이어는 UI와 최대한 독립적으로 설계되어야 하므로, @Published 선언은 서비스 레이어의 책임과 역할에 맞지 않다고 보여집니다.
     // 2. 보다 적합한 대안 함수 존재
     //   * 도전과제 데이터는 특정 액션(사용자가 도전과제를 추가하거나 수정하는 경우)에만 변경되면 됩니다.
     //   * 이에 따라, 변경 사항이 발생할 때에만 ViewModel의 변수를 업데이트하는 'updateProperties()' 함수가 충분히 그 역할을 대신할 수 있습니다.
     
    private func addSubscribers() {
        $myChallenges
            .receive(on: DispatchQueue.main)
            .sink { [weak self] myChallenges in
                DispatchQueue.main.async {
                    self?.myChallenges = myChallenges
                }
            }
            .store(in: &cancellables)
        
        $challengeList
            .receive(on: DispatchQueue.main)
            .sink { [weak self] challengeList in
                DispatchQueue.main.async {
                    self?.challengeList = challengeList.sorted(by: { $0.challengeId < $1.challengeId })
                }
            }
            .store(in: &cancellables)
    }
     */
}

//MARK: Function

extension ChallengeViewModel {
    
    func setMyChallenge(with challengeId: Int) async -> Bool {
        if await service.setMyChallenges(with: challengeId) {
            await updateProperties()
            return true
        } else {
            print("[ChallengeViewModel] Failed to set myChallenge")
            return false
        }
    }
    
    func disableMtChallenge(with challengeId: Int) async -> Bool {
        if await service.disableMyChallenge(with: challengeId) {
            await updateProperties()
            return true
        } else {
            print("[ChallengeViewModel] Failed to disable myChallenge")
            return false
        }
    }
    
    func rewardMyChallenge(with challengeId: Int) async -> Bool {
        if await service.rewardMyChallenge(with: challengeId) {
            await updateProperties()
            return true
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
