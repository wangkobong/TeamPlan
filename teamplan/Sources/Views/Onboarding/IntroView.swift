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
    @State private var selectedTab: Int = 1
    @StateObject var notificationViewModel = NotificationViewModel()
    
    var body: some View {
        ZStack {
            if isOnboarding {
                OnboardingView()
                    .transition(.asymmetric(insertion: .move(edge: .top), removal: .move(edge: .bottom)))

            } else if isLoggedIn() {
                tabView
                    .environmentObject(notificationViewModel)
                    .transition(.asymmetric(insertion: .move(edge: .bottom), removal: .move(edge: .top)))
            } else {
                LoginView()
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
//        let accessToken = keychain.get("accessToken")
        
        if let idToken = keychain.get("idToken"), !idToken.isEmpty {
            return true
        } else {
            return false
        }
    }
    
    private var tabView: some View {
        
        TabView(selection: $selectedTab) {
            ProjectView()
            .tabItem {
              Image("document")
              Text("프로젝트")
            }
            .tag(0)
            
            HomeView()
                .transition(.asymmetric(insertion: .move(edge: .bottom), removal: .move(edge: .top)))
            .tabItem {
              Image(systemName: "house")
              Text("홈")
            }
            .tag(1)
            
          Text("The Last Tab")
            .tabItem {
              Image("account")
              Text("마이페이지")
            }
            .tag(2)
        }
        .accentColor(.theme.mainPurpleColor)
    }
}
