//
//  LoginView.swift
//  teamplan
//
//  Created by sungyeon kim on 2023/02/18.
//

import SwiftUI
import GoogleSignInSwift
import AuthenticationServices

enum LoginViewState {
    case login
    case toHome
    case toSignup
}

struct LoginView: View {
    
    @State private var showTermsView: Bool = false
    @State private var showHomeView: Bool = false
    @State private var showSignUpView: Bool = false
    @State private var isLoading: Bool = false
    @State private var isLogin: Bool = false
    @State private var showAlert = false
    @AppStorage("mainViewState") var mainViewState: MainViewState?

    @ObservedObject var vm = GoogleSignInButtonViewModel()
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    
    let transition: AnyTransition = .asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading))

    var body: some View {
        NavigationView {
            ZStack {
                loginView
                    .transition(transition)
                    .zIndex(0)
                
                if isLoading {
                    LoadingView()
                        .zIndex(1)
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
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}

extension LoginView {
    
    private var loginView: some View {
        VStack {
            HStack {
                Image("loginView")
                    .padding(.trailing, 51)
                    .padding(.leading, 16)
            }
            Spacer()
                .frame(height: 100)
            
            buttons
        }
    }
    
    private var buttons: some View {
        VStack(spacing: 18) {

            SignInWithAppleButton(
                onRequest: { request in
                    // 사용자 정보 요청 설정
                    request.requestedScopes = [.fullName, .email]
                },
                onCompletion: { result in
                    switch result {
                    case .success(let authResults):
                        switch authResults.credential {
                        case let appleIDCredential as ASAuthorizationAppleIDCredential:
                            // Apple ID Credential을 사용하여 로그인 정보 처리
                            let userIdentifier = appleIDCredential.user
                            print("userIdentifier: \(userIdentifier)")
                            // 사용자 식별자(userIdentifier)를 사용하여 로그인 후의 작업 수행
                            showHomeView = true
                        default:
                            break
                        }
                    case .failure(let error):
                        // 로그인 실패 처리
                        print("Apple 로그인 실패: \(error.localizedDescription)")
                    }
                }
            )
            .padding(.horizontal)
            .frame(height: 48)
            .frame(maxWidth: .infinity)
            .foregroundColor(.theme.blackColor)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(SwiftUI.Color.theme.blackColor, lineWidth: 1)
            )


            Button(action: {}) {
                HStack {
                    Image("appleLogo")
                    Spacer()
                    Text("Apple로 계속하기")
                    Spacer()
                }
                .padding(.horizontal)
                .frame(height: 48)
                .frame(maxWidth: .infinity)
                .foregroundColor(.theme.blackColor)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(SwiftUI.Color.theme.blackColor, lineWidth: 1)
                )
            }
            
            GoogleSignInButton(viewModel: GoogleSignInButtonViewModel(scheme: .dark, style: .standard, state: .normal)) {
                Task {
                    do {
                        isLoading = true
                        let user = try await authViewModel.signInGoogle()
                  
                        switch user.status {
                        case .exist:
                            
//                            mainViewState = .signup
                            
                            let loginResult = await tryLogin()

                            if loginResult {
                                isLoading = false
                                withAnimation(.spring()) {
                                    mainViewState = .main
                                }
                            } else {
                                isLoading = false
                                showAlert = true
                            }
 
                        case .new:
                            isLoading = false
                            withAnimation(.spring()) {
                                mainViewState = .signup
                            }
                        /*
                        case .unknown:
                            isLoading = false
                            break
                        */
                        }
                        
                    } catch {
                        print(error.localizedDescription)
                        isLoading = false
                    }
                }
            }
        }
        .padding(.horizontal, 55)
    }
}


//MARK: - METHODS
extension LoginView {
    private func tryLogin() async -> Bool {
        let loginResult = await authViewModel.tryLogin()
        return loginResult
    }
}
