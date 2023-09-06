//
//  ProjectView.swift
//  teamplan
//
//  Created by sungyeon kim on 2023/08/23.
//  Copyright © 2023 team1os. All rights reserved.
//

import SwiftUI

struct ProjectView: View {
    
    @State private var isNotificationViewActive = false
    
    var body: some View {
        VStack {
            navigationArea
                .padding(.top, 20)
                .padding(.horizontal, 15)
            Spacer()
            Text("프로젝트가 텅! 비었어요")
                .font(.appleSDGothicNeo(.semiBold, size: 20))
                .foregroundColor(.theme.blackColor)
                .padding(.bottom, 15)
            
            VStack(spacing: 0) {
                Text("무엇이든 하고싶은 프로젝트를 시작해보세요")
                Text("투두팡에서 무한한 당신의 잠재력을 기록해보아요")
            }
            .font(.appleSDGothicNeo(.regular, size: 16))
            .foregroundColor(.theme.blackColor)
            .padding(.bottom, 25)
            
            Image("project_empty")
                .padding(.bottom, 60)
            
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
            .onTapGesture {
                print("프로젝트 생성하기")
            }
            
            Spacer()
        }
    }
}

struct ProjectView_Previews: PreviewProvider {
    static var previews: some View {
        ProjectView()
    }
}

extension ProjectView {
    private var navigationArea: some View {
        HStack {
            Text("logo")
                .font(.archivoBlack(.regular, size: 20))
                .foregroundColor(.theme.mainPurpleColor)
            Spacer()
            NavigationLink(destination: NotificationView(), isActive: $isNotificationViewActive) {
                Image(systemName: "bell")
                    .foregroundColor(.black)
            }
            
        }

    }
}
