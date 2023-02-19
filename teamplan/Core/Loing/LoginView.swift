//
//  LoginView.swift
//  teamplan
//
//  Created by sungyeon kim on 2023/02/18.
//

import SwiftUI

struct LoginView: View {
    var body: some View {
        VStack {
            HStack {
                Image("loginView")
                    .padding(.trailing, 51)
                    .padding(.leading, 16)
            }
            Spacer()
                .frame(height: 100)
            
            LoginButtonsView()
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}

struct LoginButtonsView: View {
    var body: some View {
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
            .padding(.horizontal, 55)
            
            Button(action: {}) {
                HStack {
                    Image("appleLogo")
                    Spacer()
                    Text("Google로 계속하기")
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
            .padding(.horizontal, 55)
        }
    }
}
