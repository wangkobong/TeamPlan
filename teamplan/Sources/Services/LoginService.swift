//
//  LoginService.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/09/06.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation

final class LoginService{
    
    let google = AuthGoogleServices()
    
    //====================
    // MARK: GoogleLogin
    //====================
    func googleLogin() async {
        
        // Try Google Social Login
        await google.login(){ result in
            switch result{
                
            //Successfully lgoin & Authentication
            case .success(let authUser):
                
                // TODO: return type
                print(authUser)
                
            // Error Handling
            case .failure(let error):
                print(error)
                
                // TODO: case1. missing TopViewController
                // TODO: case2. firebase authentication error
                // TODO: case3. Google Social Login error
            }
        }
    }
    
    
    //====================
    // MARK: AppleLogin
    //====================
    
    func appleLogin(){
        // TODO: (optional) set appllogin function
    }
}
