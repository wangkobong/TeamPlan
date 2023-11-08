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
    
    let transition: AnyTransition = .asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading))

    // onboarding inputs
    @State var dateOfBirth: String = ""
    @State var gender: String = ""
    
    // for the alert
    @State var alertTitle: String = ""
    @State var showAlert: Bool = false
    
    // goal
    @State var goalCount: String = ""
    
    @State var showHome: Bool = false
    
    var body: some View {
        NavigationView {

            
            VStack {
                Spacer()
                    .frame(height: 34)

                levelBar
                
                Spacer()
                    .frame(height: 42)
                
                
                ZStack {
                    switch signupState {
                    case 0:
                        profileSection
                            .transition(transition)
//                    case 1:
//                        jobSection
//                            .transition(transition)
//                    case 2:
//                        interestSection
//                            .transition(transition)
//                    case 3:
//                        abilitiesSection
//                            .transition(transition)
//                    case 4:
//                        goalSection
//                            .transition(transition)
                    default:
                        RoundedRectangle(cornerRadius: 25)
                            .foregroundColor(.green)
                    }
                }
                
                Spacer()
                
                bottomButton

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
        }
    }
    
}

//struct SignupView_Previews: PreviewProvider {
//    static var previews: some View {
//        SignupView(viewModel: <#SignupViewModel#>)
//    }
//}

// MARK: - COMPONENTS
extension SignupView {
    

    
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

//                HStack {
//                    Text("생년월일")
//                        .font(.appleSDGothicNeo(.regular, size: 16))
//                        .foregroundColor(Color(hex: "4B4B4B"))
//                    Spacer()
//                }
//                TextField("0000.00.00", text: $dateOfBirth)
//                    .padding(.horizontal, 10)
//                Divider()
//
//                HStack {
//                    Text("입력하신 생년월일이 맞나요?🥲")
//                        .font(.appleSDGothicNeo(.regular, size: 16))
//                        .foregroundColor(.theme.warningRedColor)
//                        .opacity(0.0)
//                    Spacer()
//                }
            }
            .padding(.horizontal, 16)

        }

    }
//
//    private var jobSection: some View {
//
//        VStack {
//            HStack {
//                Text("어떤 일을 하시나요?")
//                    .foregroundColor(Color(hex: "2B2B2B"))
//                    .font(.appleSDGothicNeo(.semiBold, size: 25))
//                Spacer()
//            }
//            .padding(.horizontal, 16)
//
//            Spacer()
//                .frame(height: 7)
//
//            HStack {
//                Text("프로필에 표시해놓을 수 있어요!")
//                    .foregroundColor(.theme.greyColor)
//                    .font(.appleSDGothicNeo(.regular, size: 16))
//                Spacer()
//            }
//            .padding(.horizontal, 16)
//
//            WrappingHStack(signupViewModel.jobs, id: \.self) { job in
//                VStack {
//                    Text(job.title)
//                        .foregroundColor(job.isSelected ? Color.theme.warningRedColor : Color.theme.blackColor)
//                        .padding(.horizontal, 20)
//                        .padding(.vertical, 10)
//                        .overlay {
//                            Capsule()
//                                .stroke(Color.black, lineWidth: 1)
//    //                                .background(signupViewModel.jobs[index].isSelected ? Color.theme.mainPurpleColor : Color.theme.whiteColor)
//                        }
//
//                    Spacer()
//                        .frame(height: 10)
//                }
//                .onTapGesture {
//                    let jobTitle = job.title
//                    guard let index = signupViewModel.jobs.firstIndex(where: {$0.title == jobTitle}) else { return }
//                    signupViewModel.jobs[index].isSelected.toggle()
//                    if signupViewModel.jobs[index].isSelected {
//                        signupViewModel.selectedJobs.append(jobTitle)
//                    } else {
//                        if let index = signupViewModel.selectedJobs.firstIndex(of: jobTitle) {
//                            signupViewModel.selectedJobs.remove(at: index )
//                        } else {
//                            print("인덱스 없음")
//                        }
//
//                    }
//                    print(signupViewModel.selectedJobs)
//                }
//            }
//            .padding()
//
//        }
//    }
//
//    private var interestSection: some View {
//        VStack {
//            HStack {
//                Text("어떤 분야에 관심있으신가요??")
//                    .foregroundColor(Color(hex: "2B2B2B"))
//                    .font(.appleSDGothicNeo(.semiBold, size: 25))
//                Spacer()
//            }
//            .padding(.horizontal, 16)
//
//            Spacer()
//                .frame(height: 7)
//
//            HStack {
//                Text("관심분야를 프로필에 나타낼 수 있어요!")
//                    .foregroundColor(.theme.greyColor)
//                    .font(.appleSDGothicNeo(.regular, size: 16))
//                Spacer()
//            }
//            .padding(.horizontal, 16)
//
//            WrappingHStack(signupViewModel.interests, id: \.self) { interest in
//                VStack {
//                    Text(interest.title)
//                        .foregroundColor(interest.isSelected ? Color.theme.warningRedColor : Color.theme.blackColor)
//                        .padding(.horizontal, 20)
//                        .padding(.vertical, 10)
//                        .overlay {
//                            Capsule()
//                                .stroke(Color.black, lineWidth: 1)
//    //                                .background(signupViewModel.jobs[index].isSelected ? Color.theme.mainPurpleColor : Color.theme.whiteColor)
//                        }
//
//                    Spacer()
//                        .frame(height: 10)
//                }
//                .onTapGesture {
//                    let interestTitle = interest.title
//                    guard let index = signupViewModel.interests.firstIndex(where: {$0.title == interestTitle}) else { return }
//                    signupViewModel.interests[index].isSelected.toggle()
//                    if signupViewModel.interests[index].isSelected {
//                        signupViewModel.selectedInterests.append(interestTitle)
//                    } else {
//                        if let index = signupViewModel.selectedInterests.firstIndex(of: interestTitle) {
//                            signupViewModel.selectedInterests.remove(at: index )
//                        } else {
//                            print("인덱스 없음")
//                        }
//
//                    }
//                    print(signupViewModel.selectedInterests)
//                }
//            }
//            .padding()
//
//        }
//    }
//
//    private var abilitiesSection: some View {
//        VStack {
//            HStack {
//                Text("당신의 능력 BEST 4는 무엇인가요?")
//                    .foregroundColor(Color(hex: "2B2B2B"))
//                    .font(.appleSDGothicNeo(.semiBold, size: 25))
//                Spacer()
//            }
//            .padding(.horizontal, 16)
//
//            Spacer()
//                .frame(height: 7)
//
//            HStack {
//                Text("BEST 능력을 통해 나의 장점을 어필할 수 있어요!")
//                    .foregroundColor(.theme.greyColor)
//                    .font(.appleSDGothicNeo(.regular, size: 16))
//                Spacer()
//            }
//            .padding(.horizontal, 16)
//
//            WrappingHStack(signupViewModel.abilities, id: \.self) { ability in
//                VStack {
//                    Text(ability.title)
//                        .foregroundColor(ability.isSelected ? Color.theme.warningRedColor : Color.theme.blackColor)
//                        .padding(.horizontal, 20)
//                        .padding(.vertical, 10)
//                        .overlay {
//                            Capsule()
//                                .stroke(Color.black, lineWidth: 1)
//    //                                .background(signupViewModel.jobs[index].isSelected ? Color.theme.mainPurpleColor : Color.theme.whiteColor)
//                        }
//
//                    Spacer()
//                        .frame(height: 10)
//                }
//                .onTapGesture {
//                    let abilityTitle = ability.title
//                    guard let index = signupViewModel.interests.firstIndex(where: {$0.title == abilityTitle}) else { return }
//                    signupViewModel.abilities[index].isSelected.toggle()
//                    if signupViewModel.abilities[index].isSelected {
//                        signupViewModel.selectedInterests.append(abilityTitle)
//                    } else {
//                        if let index = signupViewModel.selectedInterests.firstIndex(of: abilityTitle) {
//                            signupViewModel.selectedAbilities.remove(at: index )
//                        } else {
//                            print("인덱스 없음")
//                        }
//
//                    }
//                    print(signupViewModel.selectedAbilities)
//                }
//            }
//            .padding()
//        }
//    }
//
//    private var goalSection: some View {
//        VStack {
//            HStack {
//                Text("당신의 목표를 설정해주세요!")
//                    .foregroundColor(Color(hex: "2B2B2B"))
//                    .font(.appleSDGothicNeo(.semiBold, size: 25))
//                Spacer()
//            }
//            .padding(.horizontal, 16)
//            Spacer()
//                .frame(height: 7)
//            HStack {
//                Text("목표를 설정하면\n당신의 목표달성률을 확인할 수 있어요")
//                    .foregroundColor(.theme.greyColor)
//                    .font(.appleSDGothicNeo(.regular, size: 16))
//                Spacer()
//            }
//            .padding(.horizontal, 16)
//
//
//            VStack(spacing: 23) {
//                HStack {
//                    Spacer()
//                        .frame(width: 16)
//                    Text("차근차근 도전하자!👊 3개 도전")
//                        .frame(height: 41, alignment: .leading)
//                        .frame(maxWidth: .infinity)
//                        .overlay(
//                             RoundedRectangle(cornerRadius: 2)
//                                 .stroke(Color.black, lineWidth: 1)
//                         )
//                    Spacer()
//                        .frame(width: 16)
//                }
//
//                HStack {
//                    Spacer()
//                        .frame(width: 16)
//                    Text("더 힘내볼까?👊 5개 도전")
//                        .frame(height: 41, alignment: .leading)
//                        .frame(maxWidth: .infinity)
//                        .overlay(
//                             RoundedRectangle(cornerRadius: 2)
//                                 .stroke(Color.black, lineWidth: 1)
//                         )
//                    Spacer()
//                        .frame(width: 16)
//                }
//
//                HStack {
//                    Spacer()
//                        .frame(width: 16)
//                    Text("나는 파워 계획러~👊 10개 도전")
//                        .frame(height: 41, alignment: .leading)
//                        .frame(maxWidth: .infinity)
//                        .overlay(
//                             RoundedRectangle(cornerRadius: 2)
//                                 .stroke(Color.black, lineWidth: 1)
//                         )
//                    Spacer()
//                        .frame(width: 16)
//                }
//
//
//                HStack {
//                    Spacer()
//                        .frame(width: 16)
//                    TextField("직접 입력하기", text: $goalCount)
//                        .frame(height: 41, alignment: .leading)
//                        .frame(maxWidth: .infinity)
//                        .padding(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 0))
//                        .overlay(
//                             RoundedRectangle(cornerRadius: 2)
//                                 .stroke(Color.black, lineWidth: 1)
//                         )
//                    Spacer()
//                        .frame(width: 16)
//                }
//
//
//            }
//
//        }
//    }
    
    private var bottomButton: some View {
        
//        Text(signupState == 4 ? "완료" : "다음")
        
        Text("완료")
            .frame(width: 300, height: 96)
            .frame(maxWidth: .infinity)
            .background(self.checkValidUserName() ? Color.theme.mainPurpleColor : .theme.whiteGreyColor)
            .foregroundColor(.theme.whiteColor)
            .disabled(self.checkValidUserName())
            .font(.appleSDGothicNeo(.regular, size: 20))
            .onTapGesture {
                Task {
                    await trySignup()
                }
            }
    }
    
    private func checkValidUserName() -> Bool {
        return self.userName.count > 5 ? true : false
        
    }
}

// MARK: - FUNCTIONS

extension SignupView {
    
    private func handleNextButtonPresses() {
//        switch signupState {
//        case 0:
//            print("profileSection")
//        case 1:
//            print("jobSection")
//        case 2:
//            print("interestSection")
//        case 3:
//            print("abilitiesSection")
//        case 4:
//            print("goalSection")
////            showHome = true
//        default:
//            break
//        }
//
//        if signupState == 4 {
//            print("완료")
//        } else {
//            withAnimation(.spring()) {
//                signupState += 1
//            }
//        }
    }
    
    private func getCurrentLevelBarColor(index: Int) -> Color {
        if index == signupState {
            return .theme.whiteGreyColor
        } else {
            return .theme.mainBlueColor
        }
    }
    
    private func trySignup() async {
        do {
            try await authViewModel.trySignup(userName: self.userName)
        } catch let error {
            print("trySignup error: \(error)")
        }
    }

}
