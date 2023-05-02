//
//  teamplanApp.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/02/15.
//

import SwiftUI
import GoogleSignIn

@main
struct teamplanApp: App {
    // 온보딩 관련 State
    @State private var showIntroView: Bool = true
    
    // Firebase 관련
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    // GoogleSignIn 관련
    @StateObject var googleAuthViewModel = GoogleAuthViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(googleAuthViewModel)
                .onAppear {
                    GIDSignIn.sharedInstance.restorePreviousSignIn{
                        user, error in
                        if let user = user {
                            self.googleAuthViewModel.state = .signedIn(user)
                        }else if let error = error {
                            self.googleAuthViewModel.state = .signedOut
                            print("There was an error restoring the previous sign-in: \(error)")
                        }else{
                            self.googleAuthViewModel.state = .signedOut
                        }
                    }
                }
                .onOpenURL{ url in
                    GIDSignIn.sharedInstance.handle(url)
                }
            /*  Google 로그인 테스트를 위해 주석처리
            ZStack {
                ZStack {
                    if showIntroView {
                        SplashView(showIntroView: $showIntroView)
                            .transition(.move(edge: .leading))
                    } else {
                        IntroView()
                    }
                }
            }
             */
        }
    }
}
