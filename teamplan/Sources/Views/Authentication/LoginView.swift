//
//  LoginView.swift
//  teamplan
//
//  Created by sungyeon kim on 2023/02/18.
//

import SwiftUI
import GoogleSignInSwift

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


