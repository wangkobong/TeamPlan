//
//  IntroView.swift
//  teamplan
//
//  Created by sungyeon kim on 2023/02/18.
//

import SwiftUI
import FirebaseAuth

enum MainViewState: Int {
    case login
    case signup
    case main
}

struct IntroView: View {
    
    @AppStorage("isOnboarding") var isOnboarding: Bool = true
    @AppStorage("mainViewState") var mainViewState: MainViewState = .login
    
    @StateObject var notificationViewModel = NotificationViewModel()
    @State private var isLoading: Bool = false
    
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    
    var body: some View {
        ZStack {
            if isOnboarding {
                OnboardingView()
                    .transition(.asymmetric(insertion: .move(edge: .top), removal: .move(edge: .bottom)))
            } else {
                if isLoading {
                    LoadingView()
                } else {
                    moveToMainView
                }
            }
        }
        .onAppear {
            Task {
                await autoLoginProcess()
            }
        }
    }
    
    @ViewBuilder
    private var moveToMainView: some View {
        switch mainViewState {
        case .login:
            LoginView().environmentObject(notificationViewModel)
        case .signup:
            SignupView().environmentObject(notificationViewModel)
        case .main:
            MainTapView().environmentObject(notificationViewModel)
        }
    }
}

//MARK: AutoLogin

extension IntroView {
    
    // Main Executor
    private func autoLoginProcess() async {
        isLoading = true
        
        let volt = VoltManager.shared
        if let userId = volt.getUserId(),
           let userName = volt.getUserName() {
            let loginResult = await authViewModel.tryLogin(userId: userId)
            self.mainViewState = loginResult ? .main : .login
        } else {
            self.mainViewState = .login
        }
        isLoading = false
    }
}

struct IntroView_Previews: PreviewProvider {
    static var previews: some View {
        IntroView()
    }
}



