//
//  LoginView.swift
//  teamplan
//
//  Created by sungyeon kim on 2023/02/18.
//

import SwiftUI

struct LoginView: View {
    
    @AppStorage("mainViewState") var mainViewState: MainViewState?

    let transition: AnyTransition = .asymmetric(
        insertion: .move(edge: .trailing),
        removal: .move(edge: .leading)
    )
    
    // MARK: View Config
    
    var body: some View {
        NavigationView {
            ZStack {
                loginView
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
            
            Button(action: {
                withAnimation(.spring()) {
                    mainViewState = .signup
                }
            }) {
                Text("시작하기")
                    .font(.appleSDGothicNeo(.bold, size: 17))
                    .foregroundColor(.theme.whiteColor)
                    .frame(height: 48)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(hex: "007AFF"))
                    )
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
}

 struct LoginView_Previews: PreviewProvider {
     static var previews: some View {
         LoginView()
     }
 }
