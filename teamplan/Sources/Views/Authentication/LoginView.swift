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
    
    @AppStorage("mainViewState") var mainViewState: MainViewState?
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    
    @State private var isLoading: Bool = false
    @State private var showLoginAlert: Bool = false
    
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
            .alert(isPresented: $showLoginAlert) {
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
            Spacer()
                .frame(height: 100)
            texts
            
            images
            
            Spacer()
                .frame(height: 60)
                            
            buttons
            
            Spacer()
            
            descriptions
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "60B9FF").opacity(0.6), Color(hex: "7248E1").opacity(0.6)]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .transition(transition)
        .zIndex(0)
    }
    
    private var texts: some View {
        VStack {
            Text("'완벽'보다 '완료를 추구하는")
                .font(.appleSDGothicNeo(.bold, size: 17))
                .foregroundColor(.theme.whiteColor)
                .frame(height: 32)
                .frame(maxWidth: .infinity)
                .background(SwiftUI.Color.theme.mainPurpleColor)
                .cornerRadius(24)
                .padding(.horizontal, 62)
            
            Spacer()
                .frame(height: 37)
            
            Image(uiImage: Gen.Images.todopangLogoLoginView.image)
                .frame(width: 177, height: 80)
        }
    }
    
    private var images: some View {
        ZStack {
            
            Image(uiImage: Gen.Images.squareLoginView2.image)
                .frame(width: 127, height: 127)
                .offset(y: -35)
                .offset(x: 60)
            
            
            Image(uiImage: Gen.Images.waterdropIconLoginView.image)
                .frame(width: 81, height: 97)
                .offset(y: -10)
                .offset(x: -70)
            
            Image(uiImage: Gen.Images.bombIconLoginView.image)
                .frame(width: 107, height: 145)
                .offset(y: 5)
                .offset(x: 20)
            
            Image(uiImage: Gen.Images.squareLoginView1.image)
                .frame(width: 76, height: 76)
                .offset(y: 63)
                .offset(x: -90)
        }
    }
    
    private var buttons: some View {
        VStack(spacing: 12) {
            
            ZStack {
                HStack {
                    Spacer()
                        .frame(width: 40)
                    Image(uiImage: Gen.Images.googleLogoLoginView.image)
                    Spacer()
                }
                Text("구글 로그인")
                    .font(.appleSDGothicNeo(.bold, size: 17))
                    .foregroundColor(.theme.blackColor)
            }
            .frame(height: 48)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(Gen.Colors.whiteColor.swiftUIColor)
            )
            .overlay {
                GoogleSignInButton(viewModel: self.signInViewModel) {
                    googleLoginProcess()
                }
                .blendMode(.overlay)
            }

            
            ZStack {
                HStack {
                    Spacer()
                        .frame(width: 40)
                    Image(uiImage: Gen.Images.appleLogoLoginView.image)
                    Spacer()
                }
                Text("애플 로그인")
                    .font(.appleSDGothicNeo(.bold, size: 17))
                    .foregroundColor(.theme.whiteColor)
            }
            .frame(height: 48)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(hex: "000000"))
            )
            .overlay {
                SignInWithAppleButton(
                    onRequest: appleLoginRequest,
                    onCompletion: appleLoginProcess
                )
                .blendMode(.overlay)
            }
        }
        .padding(.horizontal, 55)
    }
    
    private var descriptions: some View {
        VStack {
            Image(uiImage: Gen.Images.descriptionLoginView.image)
                .frame(height: 32)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 34)
        }
    }
    
    // MARK: Function
    
    // Apple login
    // TODO: Need Custom Exception
    private func appleLoginRequest(request: ASAuthorizationAppleIDRequest) {
        self.isLoading = true
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
            print("[Login View] Apple Social Login Falied: \(error.localizedDescription)")
            showLoginAlert = true
            isLoading = false
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
                print("[Login View] Google login failed: \(error.localizedDescription)")
                showLoginAlert = true
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
                if authViewModel.isReSignupNeeded {
                    withAnimation(.spring()) {
                        mainViewState = .signup
                    }
                } else {
                    showLoginAlert = true
                }
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
