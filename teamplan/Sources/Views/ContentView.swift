//
//  ContentView.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/02/15.
//

import SwiftUI
import GoogleSignIn

struct ContentView: View {
    // GoogleSignIn 관련
    @EnvironmentObject var googleAuthViewModel: GoogleAuthViewModel
    
    var body: some View {
        return Group {
            NavigationView {
                switch googleAuthViewModel.state{
                case .signedIn:
                    LoginView()
                        .navigationTitle(
                        NSLocalizedString("Signed In State", comment: "Signed In State Navi Title"))
                case .signedOut:
                    LoginView()
                        .navigationTitle(
                        NSLocalizedString("Signed Out State", comment: "Signed Out State Navi Title"))
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
