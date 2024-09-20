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
    
    private let identifier: String
    private let userName: String
    private var cancellables = Set<AnyCancellable>()
    private let service: HomeService

    //MARK: Initialize

    @MainActor
    init() {
        let volt = VoltManager.shared
        if let identifier = volt.getUserId(),
           let userName = volt.getUserName() {
            self.identifier = identifier
            self.userName = userName
        } else {
            print("[HomeViewModel] ViewModel Initialize Failed")
            self.identifier = "unknown"
            self.userName = "unknown"
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
