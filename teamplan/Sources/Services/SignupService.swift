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
    func getAccountInfo(newUser: AuthSocialLoginResDTO) -> UserSignupDTO? {
        
        // create identifier
        let identifier = util.getIdentifier(authRes: newUser)
        
        if identifier != "" {
            
            return UserSignupDTO(identifier: identifier, email: newUser.email, provider: newUser.provider)
        } else {
            return nil
        }
    }
    
    //===============================
    // MARK: - Set NickName
    //===============================
    func setNickName(newUser: UserSignupDTO, nickName: String) -> UserSignupDTO {
        let updatedUserSignup = UserSignupDTO(identifier: newUser.identifier, email: newUser.email, provider: newUser.provider, nickname: nickName)
        return updatedUserSignup
    }
}
