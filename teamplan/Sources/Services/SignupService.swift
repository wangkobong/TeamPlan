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
    // Becuase of Struct 'UserSignupReqDTO' contain success/failure case, can't deploy init()
    var userInfo: UserSignupReqDTO? = nil
    init(){}
    
    //===============================
    // MARK: - Get AccountInfo
    //===============================
    func getAccountInfo(newUser: AuthSocialLoginResDTO,
                        result: @escaping(Result<UserSignupResDTO, Error>) -> Void) {
        
        // extract AccountName from SocialLogin Result
        let accName = util.getAccountName(userEmail: newUser.email)
        
        if accName == "" {
            return result(.failure(EmailError.invalidEmailFormat))
        } else {
            // create identifier
            let identifier = "\(accName)_\(newUser.provider.rawValue)"
            
            // set basic profile info for signup
            self.userInfo = UserSignupReqDTO(identifier: identifier, email: newUser.email, provider: newUser.provider)
            
            // return UserInfo that require SignupView
            return result(.success(UserSignupResDTO(accountName: accName, provider: newUser.provider)))
        }
    }
    
    //===============================
    // MARK: - Set NickName
    //===============================
    func setNickName(nickName: String) -> UserSignupReqDTO {
        
        self.userInfo?.addNickName(nickName: nickName)
        return self.userInfo!
    }
}
