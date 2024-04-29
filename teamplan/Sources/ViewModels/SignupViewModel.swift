//
//  SignupViewModel.swift
//  teamplan
//
//  Created by sungyeon kim on 2023/06/08.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation
import Combine
import KeychainSwift

final class SignupViewModel: ObservableObject {
    
    @Published var nickName: String = ""
    @Published var test = true
    
    let signupUser: AuthSocialLoginResDTO
    private var cancellables = Set<AnyCancellable>()
    
    init(signupUser: AuthSocialLoginResDTO) {
        self.signupUser = signupUser
        self.addSubscribers()
    }
    
    private func addSubscribers() {
        $nickName
            .sink { [weak self] name in
                if name.count > 5 {
                    self?.test = false
                } else {
                    self?.test = true
                }
                
            }
            .store(in: &cancellables)
    }
}
