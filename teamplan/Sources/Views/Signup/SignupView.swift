//
//  SignupView.swift
//  teamplan
//
//  Created by sungyeon kim on 2023/06/08.
//  Copyright © 2023 team1os. All rights reserved.
//

import SwiftUI
import WrappingHStack

struct SignupView: View {
    
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @Environment(\.dismiss) var dismiss
    @State var signupState: Int = 0
    @State var userName: String = ""
    @State private var signupSuccess = false
    @AppStorage("mainViewState") var mainViewState: MainViewState?

    let transition: AnyTransition = .asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading))

    // onboarding inputs
    @State var dateOfBirth: String = ""
    @State var gender: String = ""
    
    // for the alert
    @State private var alertTitle: String = ""
    @State private var showAlert = false
    
    // goal
    @State var goalCount: String = ""
    
    @State var showHome: Bool = false
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack {
                    Spacer()
                        .frame(height: 34)
                    self.levelBar
                    Spacer()
                        .frame(height: 42)
                    ZStack {
                        switch signupState {
                        case 0:
                            profileSection
                                .transition(transition)
                        default:
                            RoundedRectangle(cornerRadius: 25)
                                .foregroundColor(.green)
                        }
                    }
                    Spacer()
                    self.bottomButton
                }
                if self.isLoading {
                    LoadingView()
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        if signupState == 0 {
                            dismiss.callAsFunction()
                        } else {
                            withAnimation(.spring()) {
                                signupState -= 1
                            }
                        }
                    } label: {
                        Image(systemName: "chevron.backward")
                            .foregroundColor(.theme.darkGreyColor)
                    }
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("회원가입 실패"),
                    message: Text("회원가입에 실패했습니다."),
                    dismissButton: .default(Text("확인"))
                )
            }
        }
    }

    // MARK: - components
    
    private var levelBar: some View {
        
        HStack(spacing: 3) {
            ForEach(0..<5) { index in
                Rectangle()
                    .fill(getCurrentLevelBarColor(index: index))
                    .frame(width: 70, height: 5)
                    .cornerRadius(4)
            }
        }
        .padding(.horizontal, 5)
        .frame(height: 5)
    }
    
    
    private var profileSection: some View {
        
        VStack {
            HStack {
                Text("프로필을 만들어보세요!")
                    .foregroundColor(Color(hex: "2B2B2B"))
                    .font(.appleSDGothicNeo(.semiBold, size: 25))
                Spacer()
            }
            .padding(.horizontal, 16)
            Spacer()
                .frame(height: 81)
            VStack {
                HStack {
                    Text("닉네임")
                        .font(.appleSDGothicNeo(.regular, size: 18))
                        .foregroundColor(Color(hex: "4B4B4B"))
                    Spacer()
                }
                TextField("닉네임을 입력해 주세요(10자 이내)", text: $userName)
                    .padding(.horizontal, 10)
                Divider()
                HStack {
                    Text("이미 사용중인 닉네임이에요🥲")
                        .font(.appleSDGothicNeo(.regular, size: 16))
                        .foregroundColor(.theme.warningRedColor)
                        .opacity(0.0)
                    Spacer()
                }
                Spacer()
                    .frame(height: 20)
            }
            .padding(.horizontal, 16)
        }
    }
    
    
    private var bottomButton: some View {
        
        Text("완료")
            .frame(width: 300, height: 96)
            .frame(maxWidth: .infinity)
            .background(self.checkValidUserName() ? Color.theme.mainPurpleColor : .theme.whiteGreyColor)
            .foregroundColor(.theme.whiteColor)
            .disabled(!self.checkValidUserName())
            .font(.appleSDGothicNeo(.regular, size: 20))
            .onTapGesture {
                self.isLoading = true
                Task {
                    if await trySignup() {
                        self.signupSuccess = true
                        self.isLoading = false
                        mainViewState = .main
                    } else {
                        self.showAlert = true
                        self.isLoading = false
                    }
                }
            }
    }
    
    
    // MARK: - private method
    
    private func checkValidUserName() -> Bool {
        return self.userName.count > 5 ? true : false
        
    }
    
    private func getCurrentLevelBarColor(index: Int) -> Color {
        if index == signupState {
            return Gen.Colors.whiteGreyColor.swiftUIColor
        } else {
            return Gen.Colors.mainBlueColor.swiftUIColor
        }
    }
    
    private func trySignup() async -> Bool {
        return await authViewModel.trySignup(userName: self.userName)
    }
}
