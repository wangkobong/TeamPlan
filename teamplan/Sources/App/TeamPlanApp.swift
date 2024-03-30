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
  
    //====================
    // MARK: Main
    //====================
    var body: some Scene {
        WindowGroup {
            mainView
                .environmentObject(authViewModel)
                .environmentObject(termsViewModel)
                .onAppear(perform: initializeApp)
                .onOpenURL(perform: handelOpenURL)
        }
    }
    
    private var mainView: some View {
        ZStack {
            if showIntroView {
                SplashView(showIntroView: $showIntroView)
                    .transition(.move(edge: .leading))
            } else {
                IntroView()
            }
        }
    }
    
    
    //====================
    // MARK: Function
    //====================
    private func initializeApp() {
        configureFirebase()
        //restorePreviousGoogleSignIn()
    }
    
    private func configureFirebase(){
        FirebaseApp.configure()
    }

    private func handelOpenURL(_ url: URL){
        GIDSignIn.sharedInstance.handle(url)
    }
}


//====================
// MARK: App Delegate
//====================
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
            return GIDSignIn.sharedInstance.handle(url)
        }
}
