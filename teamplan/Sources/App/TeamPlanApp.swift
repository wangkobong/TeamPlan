//
//  teamplanApp.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/02/15.
//

import SwiftUI
import GoogleSignIn
import FirebaseCore

@main
struct TeamPlanApp: App {
    @State private var showIntroView: Bool = true
    @StateObject var authViewModel = AuthenticationViewModel()
    @StateObject var termsViewModel = TermsViewModel()
    @StateObject var signupViewModel = SignupViewModel()
    
    //====================
    // Main
    //====================
    var body: some Scene {
        WindowGroup {
            ZStack {
                if showIntroView {
                    SplashView(showIntroView: $showIntroView)
                        .transition(.move(edge: .leading))
                } else {
                    IntroView()
                }
            }
            .environmentObject(authViewModel)
            .environmentObject(termsViewModel)
            .environmentObject(signupViewModel)
            .onAppear {
                configureFirebase()
                restorePreviousGoogleSignIn()
            }
            .onOpenURL{ url in
                handelOpenURL(url)
            }
        }
    }
    
    //====================
    // Function
    //====================

    // FireBase 초기화
    private func configureFirebase(){
        FirebaseApp.configure()
    }

    // Google 로그인정보 복원
    private func restorePreviousGoogleSignIn(){
        GIDSignIn.sharedInstance.restorePreviousSignIn{ restoreUser, error in
            if let user = restoreUser {
                let authUser = AuthenticatedUser(user: user)
                self.authViewModel.state = .signedIn(authUser)
                print("Privious Login Info Recovered")
            }else if let error = error {
                self.authViewModel.state = .signedOut
                print("There was an error restoring the previous sign-in: \(error)")
            }else{
                self.authViewModel.state = .signedOut
                print("No Privious Login Data")
            }
        }
    }

    // Google 로그인 URL Redirect
    private func handelOpenURL(_ url: URL){
        GIDSignIn.sharedInstance.handle(url)
    }
}

//====================
// App Delegate
//====================

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        // 시작 시, 딜레이 부여
        Thread.sleep(forTimeInterval: 1.5)
        
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
            return GIDSignIn.sharedInstance.handle(url)
        }
}
