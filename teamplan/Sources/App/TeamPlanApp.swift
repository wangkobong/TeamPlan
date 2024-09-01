//
//  teamplanApp.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/02/15.
//

 import SwiftUI
 import GoogleSignIn
 import FirebaseCore
 import BackgroundTasks
 import UserNotifications

 @main
 struct TeamPlanApp: App {
     
     // MARK: Properties
     
     @StateObject var authViewModel = AuthenticationViewModel()
     @StateObject var termsViewModel = TermsViewModel()
     @StateObject var appState = AppState()
     
     @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
   
     init(){
         FirebaseApp.configure()
         appDelegate.setAppState(appState)
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

     private func handelOpenURL(_ url: URL){
         GIDSignIn.sharedInstance.handle(url)
     }
 }

 // MARK: App State

 class AppState: ObservableObject {
     @Published var isBackgroundTaskComplete = false
 }

 // MARK: App Delegate

 class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
     
     private var appState: AppState?
     
     func setAppState(_ appState: AppState) {
         self.appState = appState
     }
     
     // Google Social Login
     func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
         return GIDSignIn.sharedInstance.handle(url)
     }
     
     // Background Task & Local Push
     func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
         
         // Request notification permission
         requestNotificationAuthorization()
         
         // Set notification delegate
         UNUserNotificationCenter.current().delegate = self
         
         // Check BackgroundTask Scheduler
         checkBackgroundTask()
         
         return true
     }
     
     private func requestNotificationAuthorization() {
         UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
             if granted {
                 print("[AppDelegate] Notification authorization granted")
             } else {
                 print("[AppDelegate] Notification authorization denied")
             }
         }
     }
     
     //MARK: Background: register
     
     private func checkBackgroundTask() {
         
         guard let service = BackgroundService() else {
             print("[AppDelegate] Failed to initialize backgroundService")
             clearBackgroundTask()
             return
         }
         service.scheduleTaskIfNeeded()
         clearBackgroundTask()
         return
     }
     
     @MainActor
     private func clearBackgroundTask() {
         self.appState?.isBackgroundTaskComplete = true
         print("[AppDelegate] successfully change app state")
     }
 }
