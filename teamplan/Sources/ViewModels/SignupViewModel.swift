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
    
//    @Published var jobs: [SignupModel] = []
//    @Published var interests: [SignupModel] = []
//    @Published var abilities: [SignupModel] = []
//
//    @Published var selectedJobs: [String] = []
//    @Published var selectedInterests: [String] = []
//    @Published var selectedAbilities: [String] = []
    
    @Published var nickName: String = ""
    
    @Published var test = true
    let signupUser: AuthSocialLoginResDTO
    
    
//    private let signupDataService = SignupDataService()
    private var cancellables = Set<AnyCancellable>()
    
    init(signupUser: AuthSocialLoginResDTO) {
        self.signupUser = signupUser
        self.addSubscribers()
    }
    
    private func addSubscribers() {
//        signupDataService.$jobs
//            .sink { [weak self] jobs in
//                self?.jobs = jobs
//            }
//            .store(in: &cancellables)
//
//        signupDataService.$interests
//            .sink { [weak self] interests in
//                self?.interests = interests
//            }
//            .store(in: &cancellables)
//
//        signupDataService.$abilities
//            .sink { [weak self] abilities in
//                self?.abilities = abilities
//            }
//            .store(in: &cancellables)
//
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
    
    func trySignup(newUser: UserSignupDTO) {
        
    }
    
}
