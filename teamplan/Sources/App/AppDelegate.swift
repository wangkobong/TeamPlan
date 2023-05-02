//
//  AppDelegate.swift
//  teamplan
//
//  Created by sungyeon kim on 2023/02/18.
//

import Foundation
import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        Thread.sleep(forTimeInterval: 1.5)
        
        FirebaseApp.configure()
        
        return true
    }
}
