//
//  SignupService.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/10/20.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation

final class SignupService{
    
    let util = Utilities()
    
    func getAccountInfo(newUser: AuthSocialLoginResDTO) -> UserSignupDTO {
        return UserSignupDTO(with: newUser)
    }
}

struct UserSignupDTO{
    
    let userId: String
    let email: String
    let provider: Providers
    let logHead : Int
    var nickName: String
    
    init(with dto: AuthSocialLoginResDTO) {
        self.userId = dto.identifier
        self.email = dto.email
        self.provider = dto.provider
        self.logHead = 1
        self.nickName = ""
    }

    mutating func updateNickName(with newVal: String){
        self.nickName = newVal
    }
}
