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
    
    @StateObject var authViewModel = AuthenticationViewModel()
    @StateObject var termsViewModel = TermsViewModel()
  
    // App Initialization
    init(){
        FirebaseApp.configure()
    }
    
    // MARK: Main
    
    var body: some Scene {
        WindowGroup {
            IntroView()
                .environmentObject(authViewModel)
                .environmentObject(termsViewModel)
                .onOpenURL(perform: handelOpenURL)
        }
    }
    
    // MARK: - private method

    private func handelOpenURL(_ url: URL){
        GIDSignIn.sharedInstance.handle(url)
    }
}


class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
}
