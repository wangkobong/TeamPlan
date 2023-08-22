//
//  TutorialView.swift
//  teamplan
//
//  Created by sungyeon kim on 2023/08/22.
//  Copyright © 2023 team1os. All rights reserved.
//

import SwiftUI

struct TutorialView: View {
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.init(hex: "1E1E1E").opacity(0.8)
                    .ignoresSafeArea()
                
            VStack {
                
                buttonArea
                    .padding(.top, 25)
                    .padding(.trailing, 23)
                
                Spacer()
                    .frame(height: 80)
                
                firstSection
                
                Spacer()
                
                secondSection
                
                Spacer()
                
                thirdSection

                Spacer()
                
                doNotOpenArea

            }
        }

    }
}

struct TutorialView_Previews: PreviewProvider {
    static var previews: some View {
        TutorialView()
    }
}

extension TutorialView {
    private var buttonArea: some View {
        HStack {
            Spacer()
            Button {
                dismiss.callAsFunction()
            } label: {
                Image(systemName: "xmark")
                    .foregroundColor(.white)
            }
        }
    }
    
    private var firstSection: some View {
        VStack(spacing: 0) {
            
            HStack {
                Text("①")
                    .font(.appleSDGothicNeo(.regular, size: 16))
                Spacer()
            }
            .padding(.leading, 19)

            HStack {
                VStack(alignment: .trailing) {
                    Text("투두팡을 사용하다가 어려움이 있다면")
                    Text("한번 살펴보세요.")
                }

                HStack {
                    Text("읽으러 가기")
                        .font(.appleSDGothicNeo(.bold, size: 12))
                        .foregroundColor(.theme.whiteColor)
                        .padding(.trailing, -6)
                    Image("chevron_right")
                        .frame(width: 14, height: 12)
                }
                .foregroundColor(.clear)
                .frame(width: 111, height: 28)
                .background(Color.theme.mainPurpleColor)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 0)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                    .inset(by: -1)
                    .stroke(.white, lineWidth: 2)
                )

            }
            .frame(width: .infinity)
            
        }
        .foregroundColor(.theme.whiteColor)
        .font(.appleSDGothicNeo(.regular, size: 16))

    }
    
    private var secondSection: some View {
        VStack(spacing: 0) {
            
            HStack {
                Text("②")
                Spacer()
            }
            .padding(.leading, 40)
            
            HStack {
                Spacer()
                VStack(alignment: .center) {
                    Text("프로젝트를 생성하여 여러개의 투두로 이루어진")
                    Text("하나의 프로젝트를 완성해보세요")
                }
                Spacer()
            }
            
            
            Spacer()
                .frame(height: 28)
            
            HStack() {
                Text("프로젝트 생성하기")
                    .font(.appleSDGothicNeo(.semiBold, size: 12))
                    .foregroundColor(.theme.whiteColor)
            }
            .foregroundColor(.clear)
            .frame(width: 111, height: 28)
            .background(Color.theme.mainPurpleColor)
            .cornerRadius(4)
            .shadow(color: .white.opacity(0.25), radius: 2.5, x: 0, y: 0)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .inset(by: -0.5)
                    .stroke(.white, lineWidth: 1)
            )
        }
        .foregroundColor(.theme.whiteColor)
    }
    
    private var thirdSection: some View {
        VStack(spacing: 0) {
            
            HStack {
                Text("③")
                Spacer()
            }
            .padding(.leading, 66)
            
            HStack {
                Spacer()
                VStack(alignment: .center) {
                    Text("도전과제에 도전하면 프로젝트에 필요한")
                    Text("물방울을 모을 수 있어요")
                }
                Spacer()
            }
            
            
            Spacer()
                .frame(height: 28)
            
            HStack() {
                Text("도전하기")
                    .font(.appleSDGothicNeo(.semiBold, size: 12))
                    .foregroundColor(.theme.whiteColor)
            }
            .foregroundColor(.clear)
            .frame(width: 70, height: 28)
            .background(Color(red: 0.51, green: 0.87, blue: 1))
            .cornerRadius(4)
            .shadow(color: .white.opacity(0.25), radius: 2.5, x: 0, y: 0)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .inset(by: -0.5)
                    .stroke(.white, lineWidth: 1)
            )
        }
        .foregroundColor(.theme.whiteColor)

    }
    
    
    private var doNotOpenArea: some View {
        HStack {
            Spacer()
            Image(systemName: "checkmark.circle")
            Text("앞으로 이 창을 열지 않습니다.")
        }
        .font(.appleSDGothicNeo(.regular, size: 16))
        .foregroundColor(.white)
        .padding(.bottom, 19)
        .padding(.trailing, 13)
    }
}
