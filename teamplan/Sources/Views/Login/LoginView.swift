//
//  LoginView.swift
//  teamplan
//
//  Created by sungyeon kim on 2023/02/18.
//

import SwiftUI
import GoogleSignIn
import FirebaseCore
import GoogleSignInSwift

@MainActor
final class AuthenticationViewModel: ObservableObject {
    
    func signInGoogle() async throws {
        
        let helper = SignInGoogleHelper()
        let tokens = try await helper.signIn()
        try await AuthenticationManager.shared.signInWithGoogle(tokens: tokens)
        
    }
    
}

struct LoginView: View {
    
    @State private var showTermsView: Bool = false
    @State private var showUserProfile: Bool = false
    @EnvironmentObject var googleAuthViewModel: GoogleAuthViewModel
    @ObservedObject var vm = GoogleSignInButtonViewModel()
    @StateObject private var viewModel = AuthenticationViewModel()
    
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
                
                HStack {
                    Image("loginView")
                        .padding(.trailing, 51)
                        .padding(.leading, 16)
                }
                Spacer()
                    .frame(height: 100)
                
                buttons
            }
            .onAppear {
                configureFirebase()
                restorePreviousGoogleSignIn()

                if googleAuthViewModel.user.email != "No Email Info" {
                    print("No Email Info")
                    showUserProfile = true
                }
            }
            // 최초 로그인일 경우, 로그인페이지로
            .onOpenURL{ url in
                handelOpenURL(url)
            }
        }
    }
    
    // FireBase 초기화
    private func configureFirebase(){
        FirebaseApp.configure()
    }
    
    // Google 로그인정보 확인
    private func restorePreviousGoogleSignIn(){
        GIDSignIn.sharedInstance.restorePreviousSignIn{ restoreUser, error in
            // 기존 로그인유저 정보추출
            if let user = restoreUser {
                self.googleAuthViewModel.state = .signedIn(user)
            }else if let error = error {
                self.googleAuthViewModel.state = .signedOut
                print("There was an error restoring the previous sign-in: \(error)")
            }else{
                self.googleAuthViewModel.state = .signedOut
            }
        }
    }
    
    private func handelOpenURL(_ url: URL){
        GIDSignIn.sharedInstance.handle(url)
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
                print("구글버튼클릭")
                Task {
                    do {
                        try await viewModel.signInGoogle()
                        print("구글로그인 성공")
                        showTermsView = true
                    } catch {
                        print(error)
                    }
                }
            }
        }
        .padding(.horizontal, 55)
    }
}


