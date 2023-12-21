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
        
        return UserSignupDTO(with: try util.getIdentifier(from: newUser), and: newUser)
    }
}
