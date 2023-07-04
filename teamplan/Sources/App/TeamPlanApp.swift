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
    @StateObject var googleAuthViewModel = GoogleAuthViewModel()
    @StateObject var termsViewModel = TermsViewModel()
    @StateObject var signupViewModel = SignupViewModel()
    
    // Main 파트
    var body: some Scene {
        WindowGroup {
            
            // 도입부 설정
            ZStack {
                if showIntroView {
                    SplashView(showIntroView: $showIntroView)
                        .transition(.move(edge: .leading))
                } else {
                    IntroView()
                }
            }
            .environmentObject(googleAuthViewModel)
            .environmentObject(termsViewModel)
            .environmentObject(signupViewModel)
        }
    }
}

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
