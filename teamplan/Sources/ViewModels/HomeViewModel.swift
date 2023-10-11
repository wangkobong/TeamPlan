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
    
    @Published var user: UserHomeResDTO?
    
    private let homeService = HomeService()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        self.addSubscribers()
    }
    
    private func addSubscribers() {
       
    }
    
    private func getUser() async {
        self.user = await homeService.getUser(identifier: "")
    }
}
