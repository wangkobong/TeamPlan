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
    
    var body: some View {
        ZStack {
            if isOnboarding {
                OnboardingView()
                    .transition(.asymmetric(insertion: .move(edge: .top), removal: .move(edge: .bottom)))

            } else if isLoggedIn() {
                MainTapView()
                    .environmentObject(notificationViewModel)
                    .transition(.asymmetric(insertion: .move(edge: .bottom), removal: .move(edge: .top)))
            } else {
                LoginView()
                    .environmentObject(notificationViewModel)
                    .transition(.asymmetric(insertion: .move(edge: .bottom), removal: .move(edge: .top)))
            }
        }
    }
}

struct IntroView_Previews: PreviewProvider {
    static var previews: some View {
        IntroView()
    }
}

extension IntroView {
    private func isLoggedIn() -> Bool {
        let keychain = KeychainSwift()
        let accessToken = keychain.get("accessToken")
        
        if let idToken = keychain.get("idToken"), !idToken.isEmpty {
            return true
        } else {
            return false
        }
        /* Lock for Social Login Test

         */
    }
    
}
