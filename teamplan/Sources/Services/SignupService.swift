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
    func getAccountInfo(newUser: AuthSocialLoginResDTO,
                        result: @escaping(Result<UserSignupDTO, Error>) -> Void) {
        
        // create identifier
        util.getIdentifier(authRes: newUser) { response in
            switch response {
                
            // set basic profile info for signup
            case .success(let id):
                return result(.success(UserSignupDTO(identifier: id, email: newUser.email, provider: newUser.provider)))
                
            // Exception Handling: Invalid Email Format
            case .failure(let error):
                print("(Signup) Invalid Email Format : \(error)")
                return result(.failure(error))
            }
        }
    }
    
    //===============================
    // MARK: - Set NickName
    //===============================
    func setNickName(newUser: UserSignupDTO, nickName: String) -> UserSignupDTO {
        let updatedUserSignup = UserSignupDTO(identifier: newUser.email, email: newUser.email, provider: newUser.provider, nickname: nickName)
        return updatedUserSignup
    }
}
