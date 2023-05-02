//
//  OnboardingView.swift
//  teamplan
//
//  Created by sungyeon kim on 2023/02/18.
//

import SwiftUI

struct OnboardingStep {
    let title: String
    let description: String
    let imageName: String
}

private let onBoardingSteps = [
    OnboardingStep(title: "안녕하세요", description: "대학생부터 직장인까지! \n프로젝트 관리 서비스 TEAMPLAN이에요", imageName: "onboarding_1"),
    OnboardingStep(title: "편하게", description: "언제 어디서든 \n팀원들의 진행률을 확인해요", imageName: "onboarding_2"),
    OnboardingStep(title: "한눈에", description: "공유캘린더를 통해서 \n팀,개인의 일정을 한눈에 확인해요", imageName: "onboarding_3"),
    OnboardingStep(title: "성장하는", description: "상호간의 간단한 피드백을 통해 \n프로젝트를 마무리하며 \n개인의 능력을 성장시켜요", imageName: "onboarding_4"),
]

struct OnboardingView: View {
    
    @State private var onboardingState: Int = 0
    @State private var toLoginView = false
    @State private var isPressedButton = false
    @AppStorage("isOnboarding") var isOnboarding: Bool?
    
    let transition: AnyTransition = .asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading))
    
    init() {
        UIScrollView.appearance().bounces = false
    }
    
    var body: some View {
        VStack {
            skipButton
                .frame(height: 20)
            TabView(selection: $onboardingState) {
                ForEach(0..<onBoardingSteps.count, id: \.self) { index in
                    VStack {
                        Text(onBoardingSteps[index].title)
                            .font(.appleSDGothicNeo(.bold, size: 30))
                            .foregroundColor(.theme.mainPurpleColor)
                            .padding(.bottom)
                        
                        Text(onBoardingSteps[index].description)
                            .font(.appleSDGothicNeo(.semiBold, size: 20))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 34)
                            .lineLimit(index == 3 ? 3 : 2)
                        
                        Image(onBoardingSteps[index].imageName)
                            .frame(height: 337)
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle())
            pageControl
            Spacer()
            bottomButton

        } //: VSTACK
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
    }
}

// MARK: - COMPONENTS
extension OnboardingView {
    
   private var bottomButton: some View {
       Button {
           isOnboarding = false
           isPressedButton = true
       } label: {
           Text(onboardingState == 3 ? "TEAMPLAN 시작하기" : "시작하기")
               .font(.appleSDGothicNeo(.bold, size: 20))
               .foregroundColor(.theme.whiteGreyColor)
               .frame(height: 48)
               .frame(maxWidth: .infinity)
               .background(onboardingState == 3 ? SwiftUI.Color.theme.mainPurpleColor : .white)
               .cornerRadius(10)
               .background(
                   RoundedRectangle(cornerRadius: 10)
                       .stroke(SwiftUI.Color.theme.whiteGreyColor, lineWidth: onboardingState == 3 ? 0 : 1)
               )
               .padding(.horizontal)
               .shadow(radius: onboardingState == 3 ? 0 : 2)
       }
       .disabled(onboardingState == 3 ? false : true)

   }
   
   private var pageControl: some View {
       HStack(spacing: 12) {
           ForEach(0..<onBoardingSteps.count, id: \.self) { index in
               if index == onboardingState {
                   Rectangle()
                       .frame(width: 32, height: 10)
                       .cornerRadius(10)
                       .foregroundColor(.theme.mainBlueColor)
               } else {
                   Circle()
                       .frame(width: 12, height: 12)
                       .foregroundColor(.init(hex: "D9D9D9"))
               }
           }
       }
       .padding(.bottom, 24)
   }
   
   private var skipButton: some View {
       HStack {
           if onboardingState > 0 {
               Button {
                   withAnimation(.spring()) {
                       onboardingState -= 1
                   }
               } label: {
                   Image(systemName: "chevron.backward")
                       .padding(.leading)
                       .foregroundColor(.init(hex: "#4B4B4B"))
               }
               .frame(width: 24, height: 24)
           }
           Spacer()
           Button {
               withAnimation(.spring()) {
                   onboardingState = 3
               }
           } label: {
               Text("건너뛰기")
                   .font(.appleSDGothicNeo(.regular, size: 12))
                   
           }
           .frame(width: 60, height: 16)
           .padding(.trailing)
           .foregroundColor(.theme.greyColor)
           .opacity(onboardingState == 3 ? 0.0 : 1.0)
       }
   }
}
