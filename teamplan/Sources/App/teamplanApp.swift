//
//  teamplanApp.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/02/15.
//

import SwiftUI

@main
struct teamplanApp: App {
    // 온보딩 관련 State
    @State private var showIntroView: Bool = true
    
    // Firebase 관련
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
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
        }
    }
}
