//
//  teamplanApp.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/02/15.
//

import SwiftUI

@main
struct teamplanApp: App {
    
    @State private var showIntroView: Bool = true
    
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
