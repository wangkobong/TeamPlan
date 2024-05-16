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

extension IntroView {
    
    // Main Executor
    private func autoLoginProcess() async {
        isLoading = true
        
        guard let user = Auth.auth().currentUser else {
            print("[AutoLogin] There is no currently logged in user")
            setReloginStatus()
            return
        }
        
        if await isReLoginNeeded(with: user) {
            prepareAuthDTO(with: user)
            let loginSuccess = await authViewModel.tryLogin()
            self.mainViewState = loginSuccess ? .main : .login
        } else {
            setReloginStatus()
        }
        isLoading = false
    }
    
    // check: FirebaseAuth refresh token
    private func isReLoginNeeded(with user: User) async -> Bool {
        do {
            try await user.getIDTokenResult(forcingRefresh: true)
            print("[AutoLogin] Successfully get refreshed token")
            return true
        } catch {
            print("[AutoLogin] Failed to refresh token: \(error)")
            await logoutAndRedirectToLogin()
            return false
        }
    }
    
    // struct: AuthSocialLoginDTO for 'loginLoadingService'
    private func prepareAuthDTO(with user: User) {
        self.authViewModel.signupUser = AuthSocialLoginResDTO(
            identifier: user.uid,
            email: user.email ?? "UnknownEmail",
            provider: .firebase,
            idToken: "",
            accessToken: "",
            status: .exist
        )
    }
    
    // exception: logout at firebaseAuth
    private func logoutAndRedirectToLogin() async {
        do {
            try Auth.auth().signOut()
        } catch {
            print("[AutoLogin] Failed to Logout at FirebaseAuth: \(error)")
        }
        setReloginStatus()
    }
    
    // exception: change view state
    private func setReloginStatus() {
        self.mainViewState = .login
        self.isLoading = false
    }
}

struct IntroView_Previews: PreviewProvider {
    static var previews: some View {
        IntroView()
    }
}



