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
//    @Published var userData: HomeDataDTO
//    
//    private let identifier: String
//    private let userName: String
//    private var cancellables = Set<AnyCancellable>()
//    private let service: HomeService

    //MARK: Initialize
    private let homeRepository: HomeRepository
    @Published var homeData: HomeData?

    init(homeRepository: HomeRepository = HomeRepository()) {
        self.homeRepository = homeRepository
    }
    
    func getHomeData(userId: String) async {
        do {
            let homeData = try await self.homeRepository.getHomeData(userId: userId)
            self.homeData = homeData
        } catch {
            print("getHomeData 오류: \(error)")
        }
    }

//    func prepareData() async -> Bool {
//        if self.service.prepareExecutor() {
//            await updateProperties()
//            return true
//        } else {
//            print("[HomeViewModel] Failed to Initialize ViewModel")
//            return false
//        }
//    }
//     
//    func updateData() async -> Bool {
//        if self.service.updateExecutor() {
//            await updateProperties()
//            return true
//        } else {
//            print("[HomeViewModel] Failed to update ViewModel userData")
//            return false
//        }
//    }
    
//   @MainActor
//    private func updateProperties() {
//        self.userData = service.dto
//    }
}

