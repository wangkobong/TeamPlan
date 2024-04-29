//
//  LoginView.swift
//  teamplan
//
//  Created by sungyeon kim on 2023/02/18.
//

import SwiftUI
import FirebaseAuth
import GoogleSignInSwift
import AuthenticationServices

enum LoginViewState {
    case login
    case toHome
    case toSignup
}

struct LoginView: View {
    
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @State private var isLoading: Bool = false
    @State private var showAlert: Bool = false
    @AppStorage("mainViewState") var mainViewState: MainViewState?
    
    private var signInViewModel = GoogleSignInButtonViewModel(scheme: .dark, style: .standard, state: .normal)
    
    let transition: AnyTransition = .asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading))
    
    
    // MARK: View Config
    
    var body: some View {
        NavigationView {
            ZStack {
                loginView
                if isLoading {
                    LoadingView().zIndex(1)
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("로그인 실패"),
                    message: Text("로그인을 실패했습니다."),
                    dismissButton: .default(Text("확인"))
                )
            }
        }
    }
    
    private var loginView: some View {
        VStack {
            HStack {
                Image("loginView")
                    .padding(.trailing, 51)
                    .padding(.leading, 16)
            }
            Spacer()
                .frame(height: 100)
            self.buttons
        }
        .transition(transition)
        .zIndex(0)
    }
    
    private var buttons: some View {
        VStack(spacing: 18) {
            SignInWithAppleButton(
                onRequest: appleLoginRequest,
                onCompletion: appleLoginProcess
            )
            .signInButtonStyle()
            
            GoogleSignInButton(viewModel: self.signInViewModel) {
                googleLoginProcess()
            }
        }
        .padding(.horizontal, 55)
    }
    
    
    // MARK: Function
    
    // Apple login
    // TODO: Need Custom Exception
    private func appleLoginRequest(request: ASAuthorizationAppleIDRequest) {
        request.requestedScopes = [.fullName, .email]
        request.nonce = self.authViewModel.requestNonceSignInApple()
    }
    
    private func appleLoginProcess(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authResult):
            Task{
                let userInfo = try await self.authViewModel.signInApple(with: authResult)
                await socialLoginProcess(with: userInfo)
            }
        case .failure(let error):
            print("Apple Social Login Falied: \(error.localizedDescription)")
        }
    }
    
    // Google login
    // TODO: Need Custom Exception
    private func googleLoginProcess() {
        Task {
            self.isLoading = true
            do {
                let userInfo = try await authViewModel.signInGoogle()
                await socialLoginProcess(with: userInfo)
            } catch {
                print("Google login failed: \(error.localizedDescription)")
                isLoading = false
            }
        }
    }
    
    // Login Process
    private func socialLoginProcess(with userInfo: AuthSocialLoginResDTO) async {
        isLoading = false
        switch userInfo.status {
        case .exist:
            if await authViewModel.tryLogin() {
                withAnimation(.spring()) {
                    mainViewState = .main
                }
            } else {
                showAlert = true
            }
        case .new:
            withAnimation(.spring()) {
                mainViewState = .signup
            }
        }
    }
}
     
extension View {
    func signInButtonStyle() -> some View {
        self
            .padding(.horizontal)
            .frame(height: 48)
            .frame(maxWidth: .infinity)
            .foregroundColor(Gen.Colors.blackColor.swiftUIColor)
            .background(RoundedRectangle(cornerRadius: 4).strokeBorder())
    }
}


 struct LoginView_Previews: PreviewProvider {
     static var previews: some View {
         LoginView()
     }
 }
