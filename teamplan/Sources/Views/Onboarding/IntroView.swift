//
//  IntroView.swift
//  teamplan
//
//  Created by sungyeon kim on 2023/02/18.
//

import SwiftUI
import KeychainSwift

struct IntroView: View {
    @AppStorage("isOnboarding") var isOnboarding: Bool = true
    @StateObject var notificationViewModel = NotificationViewModel()
    @State private var hasCheckedLoginStatus = false
    @State private var isLoggedIn = false
    
    var body: some View {
        ZStack {
            if isOnboarding {
                OnboardingView()
                    .transition(.asymmetric(insertion: .move(edge: .top), removal: .move(edge: .bottom)))

            } else if isLoggedIn {
                MainTapView()
                    .environmentObject(notificationViewModel)
                    .transition(.asymmetric(insertion: .move(edge: .bottom), removal: .move(edge: .top)))
            } else {
                LoginView()
                    .environmentObject(notificationViewModel)
                    .transition(.asymmetric(insertion: .move(edge: .bottom), removal: .move(edge: .top)))
            }
        }
        .onAppear {
            checkLoginStatus()
        }
    }
}

struct IntroView_Previews: PreviewProvider {
    static var previews: some View {
        IntroView()
    }
}

extension IntroView {
//    private func isLoggedIn() -> Bool {
//        let keychain = KeychainSwift()
//        let accessToken = keychain.get("accessToken")
//
//        if let idToken = keychain.get("idToken"), !idToken.isEmpty {
//            return true
//        } else {
//            return false
//        }
//        /* Lock for Social Login Test
//
//         */
//    }
    
    private func checkLoginStatus() {
        guard !hasCheckedLoginStatus else {
            return
        }
        
        let keychain = KeychainSwift()
        let accessToken = keychain.get("accessToken")
        
        if let idToken = keychain.get("idToken"), !idToken.isEmpty {
            isLoggedIn = true
        } else {
            isLoggedIn = false
        }
        
        hasCheckedLoginStatus = true
    }
    
}
