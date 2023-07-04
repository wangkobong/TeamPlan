//
//  UserProfileView.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/05/17.
//  Copyright © 2023 team1os. All rights reserved.
//

import SwiftUI

struct UserProfileView: View {
    
    @EnvironmentObject var googleAuthVM: GoogleAuthViewModel
    
    var body: some View {
        VStack{
            Text("Name: \(googleAuthVM.user.displayName ?? "missing name info")")
            Text("Email: \(googleAuthVM.user.email ?? "missing email info")")
        }
    }
}

struct UserProfileView_Previews: PreviewProvider {
    static var previews: some View {
        UserProfileView()
    }
}
