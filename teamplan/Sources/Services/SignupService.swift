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
    
    //===============================
    // MARK: - Get AccountInfo
    //===============================
    func getAccountInfo(newUser: AuthSocialLoginResDTO) throws -> UserSignupDTO {
        
        // create identifier & SignupDTO
        let userId = try util.getIdentifier(from: newUser)
        return UserSignupDTO(identifier: userId, email: newUser.email, provider: newUser.provider)
    }
    
    //===============================
    // MARK: - Set NickName
    //===============================
    func setNickName(newUser: UserSignupDTO, nickName: String) -> UserSignupDTO {

        // Complement SignupDTO
        return UserSignupDTO(identifier: newUser.identifier, email: newUser.email, provider: newUser.provider, nickname: nickName)
    }
}
