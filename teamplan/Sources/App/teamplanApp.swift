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
    @State private var showIntroView: Bool = false
    @State private var showUserProfile: Bool = false
    @StateObject var googleAuthViewModel = GoogleAuthViewModel()
    
    // Main 파트
    var body: some Scene {
        WindowGroup {
            
            // 도입부 설정
            ZStack{
                if showIntroView{
                    SplashView(showIntroView: $showIntroView)
                        .transition(.move(edge: .leading))
                } else {
                    IntroView()
                }
            }
            
            // 메인설정
            ContentView()
                .environmentObject(googleAuthViewModel)
                .sheet(isPresented: $showUserProfile){
                    UserProfileView()
                }
                .onAppear {
                    configureFirebase()
                    restorePreviousGoogleSignIn()
                    
                    if googleAuthViewModel.user.email != "No Email Info"{
                        showUserProfile = true
                    }
                }
                // 최초 로그인일 경우, 로그인페이지로
                .onOpenURL{ url in
                    handelOpenURL(url)
                }
        }
    }
    
    // FireBase 초기화
    private func configureFirebase(){
        FirebaseApp.configure()
    }
    
    // Google 로그인정보 확인
    private func restorePreviousGoogleSignIn(){
        GIDSignIn.sharedInstance.restorePreviousSignIn{ restoreUser, error in
            // 기존 로그인유저 정보추출
            if let user = restoreUser {
                self.googleAuthViewModel.state = .signedIn(user)
            }else if let error = error {
                self.googleAuthViewModel.state = .signedOut
                print("There was an error restoring the previous sign-in: \(error)")
            }else{
                self.googleAuthViewModel.state = .signedOut
            }
        }
    }
    
    private func handelOpenURL(_ url: URL){
        GIDSignIn.sharedInstance.handle(url)
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
