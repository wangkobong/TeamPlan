//
//  ProjectEmptyView.swift
//  teamplan
//
//  Created by sungyeon on 2024/02/01.
//  Copyright © 2024 team1os. All rights reserved.
//

import SwiftUI

struct ProjectEmptyView: View {
    var body: some View {
        VStack {
            
            Spacer()
            
            Image("project_empty")
                .padding(.bottom, 10)
            
            HStack {
                Text("프로젝트가")
                    .font(.appleSDGothicNeo(.regular, size: 16))
                    .foregroundColor(.theme.blackColor)
                Text("텅!")
                    .font(.appleSDGothicNeo(.semiBold, size: 18))
                    .foregroundColor(.theme.mainPurpleColor)
                Text("비었어요")
                    .font(.appleSDGothicNeo(.regular, size: 16))
                    .foregroundColor(.theme.blackColor)
            }
            .multilineTextAlignment(.center)
            
            
            Text("얼른 프로젝트를 추가해보세요")
                .font(.appleSDGothicNeo(.regular, size: 16))
                .foregroundColor(.theme.blackColor)

            HStack() {
                Image(systemName: "plus")
                    .foregroundColor(.theme.mainPurpleColor)
                    .imageScale(.small)
                Text("프로젝트 추가하기")
                    .font(.appleSDGothicNeo(.semiBold, size: 14))
                    .foregroundColor(.theme.mainPurpleColor)
                    .offset(x: -3)
                
            }
            .frame(width: 145, height: 36)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(SwiftUI.Color.theme.mainPurpleColor, lineWidth: 1)
            )
            .onTapGesture {
                print("프로젝트 생성하기")
            }
            
            Spacer()
        }
    }
}

struct ProjectEmptyView_Previews: PreviewProvider {
    static var previews: some View {
        ProjectEmptyView()
    }
}

