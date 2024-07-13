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
    
    @StateObject var authViewModel = AuthenticationViewModel()
    @StateObject var termsViewModel = TermsViewModel()
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
  
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

    private func handelOpenURL(_ url: URL){
        GIDSignIn.sharedInstance.handle(url)
    }
}

// MARK: App Delegate

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    private var backgroundTask: BackgroundTaskAboutNotification?
    private var isBackgroundTaskReady: Bool = false
    private var isRequestRegistered: Bool = false
    
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
        
        // Regist BackgroundTask Scheduler
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.teamplan.refresh", using: nil) {
            task in self.handleAppRefresh(task: task as! BGAppRefreshTask)
        }
        
        // Process Local Push
        Task {
            await executeBackgroundTask()
        }
        return true
    }

    //MARK: Local Push Schedule
    
    private func handleAppRefresh(task: BGAppRefreshTask) {
        Task {
            await executeBackgroundTask()
            task.setTaskCompleted(success: true)
        }
        scheduleAppRefresh()
    }
    
    private func scheduleAppRefresh() {
        let nextTiming = Calendar.current.nextDate(after: Date(), matching: DateComponents(hour: 0), matchingPolicy: .nextTime)!
        let request = BGAppRefreshTaskRequest(identifier: "com.teamplan.refresh")
        request.earliestBeginDate = nextTiming
        
        do {
            try BGTaskScheduler.shared.submit(request)
            self.isRequestRegistered = false
            print("[AppDelegate] App refresh scheduled at: \(nextTiming)")
        } catch {
            print("[AppDelegate] Could not schedule app refresh: \(error.localizedDescription)")
        }
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
    
    //MARK: Background Task
    // executor
    private func executeBackgroundTask() async {
        await prepareBackgroundTask()
        
        if isBackgroundTaskReady {
            if !isRequestRegistered {
                await scheduleLocalPushTask()
            } else {
                print("[AppDelegate] Local push already scheduled")
            }
        } else {
            print("[AppDelegate] Failed to initialize background task")
        }
    }
    
    private func prepareBackgroundTask() async {
        if let userDefault = UserDefaultManager.loadWith(),
           let identifier = userDefault.identifier,
           let userName = userDefault.userName {
            backgroundTask = BackgroundTaskAboutNotification(userId: identifier, userName: userName)
            isBackgroundTaskReady = true
        } else {
            print("[AppDelegate] Failed to fetch user data from UserDefault")
            isBackgroundTaskReady = false
        }
    }
    
    private func scheduleLocalPushTask() async {
        guard let backgroundTask = backgroundTask else { return }
        
        // check project notify
        if await backgroundTask.executeTask() {
            let content = UNMutableNotificationContent()
            content.title = backgroundTask.notificationMessage.title
            content.body = backgroundTask.notificationMessage.message
            content.sound = .default
            
            let timing = Calendar.current.nextDate(after: Date(), matching: DateComponents(hour: 9), matchingPolicy: .nextTime)!
            let trigger = UNCalendarNotificationTrigger(
                dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour], from: timing), repeats: false
            )
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
            
            do {
                try await UNUserNotificationCenter.current().add(request)
                self.isRequestRegistered = true
                print("[AppDelegate] Successfully scheduled Notification")
            } catch {
                self.isRequestRegistered = false
                print("[AppDelegate] Failed to scheduled Notification: \(error.localizedDescription)")
            }
        
        // no project to need notify
        } else {
            print("[AppDelegate] Background Task Not Needed")
        }
    }
}
