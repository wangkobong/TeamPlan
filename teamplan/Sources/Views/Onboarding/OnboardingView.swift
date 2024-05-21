//
//  OnboardingView.swift
//  teamplan
//
//  Created by sungyeon kim on 2023/02/18.
//

import SwiftUI

struct OnboardingStep {
    let descriptionImageName: String
    let exampleImageName: String
}

private let onBoardingSteps = [
    OnboardingStep(descriptionImageName: "onboarding_description1", exampleImageName: "onboarding_image1"),
    OnboardingStep(descriptionImageName: "onboarding_description2", exampleImageName: "onboarding_image2"),
    OnboardingStep(descriptionImageName: "onboarding_description3", exampleImageName: "onboarding_image3"),
    OnboardingStep(descriptionImageName: "onboarding_description4", exampleImageName: "onboarding_image4"),
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
            Spacer()
                .frame(height: 40)
            TabView(selection: $onboardingState) {
                ForEach(0..<onBoardingSteps.count, id: \.self) { index in
                    VStack {
                        Image(onBoardingSteps[index].descriptionImageName)
                            .frame(height: 90)
                        
                        Spacer()
                            .frame(height: 73)
                        
                        Image(onBoardingSteps[index].exampleImageName)
                            .frame(height: 390)
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle())
            Spacer()
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
       VStack {
           LinearGradient(colors: [.white, Color(.sRGB, white: 0.85, opacity: 1)], startPoint: .top, endPoint: .bottom)
                .frame(height: 7)
                .opacity(0.6)
           
           Spacer()
               .frame(height: 13)
           
           HStack {
               if onboardingState == 0 {
                   Text("다음")
                       .font(.appleSDGothicNeo(.medium, size: 20))
                       .foregroundColor(.theme.whiteColor)
                       .frame(height: 48)
                       .frame(maxWidth: .infinity)
                       .background(SwiftUI.Color.theme.mainPurpleColor)
                       .cornerRadius(24)
                       .padding(.horizontal, 15)
                       .onTapGesture {
                           withAnimation(.spring()) {
                               onboardingState += 1
                           }
                       }
               } else {
                   Text("이전")
                       .font(.appleSDGothicNeo(.medium, size: 20))
                       .foregroundColor(.theme.mainPurpleColor)
                       .frame(height: 48)
                       .frame(maxWidth: .infinity)
                       .background(.white)
                       .cornerRadius(24)
                       .background(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(SwiftUI.Color.theme.mainPurpleColor, lineWidth: 1)
                       )
                       .padding(.leading, 15)
                       .onTapGesture {
                           withAnimation(.spring()) {
                               onboardingState -= 1
                           }
                       }
                   
                   Spacer()
                       .frame(width: 10)
                   
                   Text("다음")
                       .font(.appleSDGothicNeo(.medium, size: 20))
                       .foregroundColor(.theme.whiteColor)
                       .frame(height: 48)
                       .frame(maxWidth: .infinity)
                       .background(SwiftUI.Color.theme.mainPurpleColor)
                       .cornerRadius(24)
                       .padding(.trailing, 15)
                       .onTapGesture {
                           if onboardingState == 3 {
                               isOnboarding = false
                               isPressedButton = true
                           } else {
                               withAnimation(.spring()) {
                                   onboardingState += 1
                               }
                           }
                       }
               }
           }
       }
   }
   
   private var pageControl: some View {
       HStack(spacing: 12) {
           ForEach(0..<onBoardingSteps.count, id: \.self) { index in
               Circle()
                   .frame(width: 8, height: 8)
                   .foregroundColor(index == onboardingState ? .init(hex: "D9D9D9") : .theme.mainBlueColor)
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
