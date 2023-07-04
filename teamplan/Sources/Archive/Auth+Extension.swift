//
//  Auth+Extension.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/05/18.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation
import GoogleSignIn
import FirebaseAuth

extension GoogleUser{
    init(googleUser: GIDGoogleUser){
        self.email = googleUser.profile?.email ?? "No Email Info"
        self.displayName = googleUser.profile?.name ?? "No profile Info"
        self.providerID = googleUser.userID ?? "No ID Info"
        self.profilePicUrl = googleUser.profile?.imageURL(withDimension: 320)
    }
    
    init(authUser: User){
        self.email = authUser.email ?? "No Email Info"
        self.displayName = authUser.displayName ?? "No profile Info"
        self.providerID = authUser.providerID
        self.profilePicUrl = authUser.photoURL
    }
}

