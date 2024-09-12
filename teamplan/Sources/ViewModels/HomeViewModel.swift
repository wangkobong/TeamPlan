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
    @Published var isViewModelProceed: Bool = false       // activated when data complete: progress to homeView
    
    private let identifier: String
    private let userName: String
    private var cancellables = Set<AnyCancellable>()
    private let service: HomeService

    //MARK: Initialize

    @MainActor
    init() {
        // UserDefault: Load Data
        let volt = VoltManager.shared
        if let identifier = volt.getUserId(),
           let userName = volt.getUserName() {
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
        self.service = HomeService(with: identifier, and: userName)
        self.userData = HomeDataDTO(with: userName)
    }

    func prepareData() async -> Bool {
        if self.service.prepareExecutor() {
            await updateProperties()
            return true
        } else {
            print("[HomeViewModel] Failed to Initialize ViewModel")
            return false
        }
    }
     
    func updateData() async -> Bool {
        if self.service.updateExecutor() {
            await updateProperties()
            return true
        } else {
            print("[HomeViewModel] Failed to update ViewModel userData")
            return false
        }
    }
    
   @MainActor
    private func updateProperties() {
        self.userData = service.dto
    }
}

// MARK: Data Change Detector
/* TODO: Need To Update with using 'userData' version
 extension HomeViewModel {
 
 func tryChallenge(with challengeId: Int) {
 Task{
 do {
 try await service.challengeSC.setMyChallenges(with: challengeId)
 await updateUserDataChallenge()
 
 } catch let error {
 // Handle the error here
 print("[HomeViewModel] Failed to Set Challenge: \(error.localizedDescription)")
 }
 }
 }
 
 func quitChallenge(with challengeId: Int) {
 Task {
 do {
 try await service.challengeSC.disableMyChallenge(with: challengeId)
 await updateUserDataChallenge()
 
 } catch let error {
 // Handle the error here
 print("[HomeViewModel] Failed to Disable Challenge: \(error.localizedDescription)")
 }
 }
 }
 
 func completeChallenge(with challengeId: Int) {
 Task {
 do {
 try await service.challengeSC.rewardMyChallenge(with: challengeId)
 await updateUserDataChallenge()
 
 } catch let error {
 // Handle the error here
 print("[HomeViewModel] Failed to Disable Challenge: \(error.localizedDescription)")
 }
 }
 }
 
 @MainActor
 private func updateUserData() async {
 self.userData = self.service.dto
 }
 
 @MainActor
 private func updateUserDataChallenge() async {
 self.userData.myChallenges = service.challengeSC.myChallenges
 self.userData.challenges = service.challengeSC.challengesDTO
 self.userData.statData = service.challengeSC.statDTO
 }
 }
 */
