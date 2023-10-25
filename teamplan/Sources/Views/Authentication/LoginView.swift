//
//  LoginView.swift
//  teamplan
//
//  Created by sungyeon kim on 2023/02/18.
//

import SwiftUI
import GoogleSignInSwift
import AuthenticationServices

struct LoginView: View {
    
    @State private var showTermsView: Bool = false
    @State private var showHomeView: Bool = false
    @State private var showUserProfile: Bool = false

    @ObservedObject var vm = GoogleSignInButtonViewModel()
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    
    var body: some View {
        NavigationView {
            VStack {
                NavigationLink(
                    destination: TermsView().defaultNavigationMFormatting(),
                     isActive: $showTermsView) {
                          Text("")
                               .hidden()
                     }
                     .navigationBarBackButtonHidden(true)
                
                NavigationLink(
                    destination: MainTapView().defaultNavigationMFormatting(),
                     isActive: $showHomeView) {
                          Text("")
                               .hidden()
                     }
                     .navigationBarBackButtonHidden(true)
                
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
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}

extension LoginView {
    
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
                        await authViewModel.signInGoogle { result in
                            switch result {
                            case .success(let user):
                                switch user.status {
                                case .exist:
                                    showHomeView = true
                                case .new:
                                    showTermsView = true
                                case .unknown:
                                    break
                                }
                            case .failure(let error):
                                print(error.localizedDescription)
                                break
                            }
                        }
     
                    }
                }
            }
        }
        .padding(.horizontal, 55)
    }
}


