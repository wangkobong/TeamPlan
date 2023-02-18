//
//  teamplanApp.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/02/15.
//

import SwiftUI

@main
struct teamplanApp: App {
    @State private var showLaunchView: Bool = true
    var body: some Scene {
        WindowGroup {
            SplashView(showOnboardingView: $showLaunchView)
        }
    }
}
