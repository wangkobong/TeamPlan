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
    
    private let homeService = HomeService(identifer: <#T##String#>)
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        self.addSubscribers()
        Task {
            await self.getUser()
        }
    }
    
    private func addSubscribers() {
       
    }
    
    private func getUser() async {
        homeService.getUser { result in
            switch result {
            case .success(let user):
                self.userName = user
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
}
