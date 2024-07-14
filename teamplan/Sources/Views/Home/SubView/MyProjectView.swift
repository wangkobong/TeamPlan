//
//  MyProjectView.swift
//  teamplan
//
//  Created by 크로스벨 on 5/20/24.
//  Copyright © 2024 team1os. All rights reserved.
//

import SwiftUI

struct MyProjectView: View {
    
    //MARK: Properties & Body
    @Binding var isProjectExist: Bool
    @State private var percent: CGFloat = 0.65
    @State private var currentPage = 0

    @ObservedObject var homeVM: HomeViewModel
    
    var body: some View {
        VStack{
            if isProjectExist {
                projectList
                    .padding(.horizontal, 16)
            } else {
                noProject
                    .padding(.horizontal, 16)
            }
        }
    }
    
    //MARK: Project Not Registed Bind
    private var noProject: some View {
        VStack {
            Image("warning_circle")
                .frame(width: 32, height: 32)
                .padding(.bottom, 5)
            Text("프로젝트를 먼저 생성해주세요")
                .font(.appleSDGothicNeo(.regular, size: 16))
                .padding(.bottom, 22)
            Text("프로젝트 생성하기")
                .font(.appleSDGothicNeo(.semiBold, size: 12))
                .foregroundColor(.theme.whiteColor)
                .frame(width: 111, height: 28)
                .background(Color.theme.mainPurpleColor)
                .cornerRadius(4)
                .onTapGesture {
                    print("프로젝트 생성하기 클릭")
                }
        }
        .frame(height: 176)
        .frame(maxWidth: .infinity)
        .clipped()
        .background(
            Rectangle()
              .foregroundColor(.clear)
              .frame(width: 358, height: 176)
              .background(.white)
              .cornerRadius(8)
              .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 0)
        )
    }
    
    //MARK: Project List & CardView
    private var projectList: some View {
        VStack {
            TabView(selection: $currentPage) {
                ForEach(Array(homeVM.userData.projectsDTOs.enumerated()), id: \.element.id) { index, project in
                    MyProjectCardView(stat: homeVM.userData.statData, project: project)
                        .tag(index)
                }
            }
            .frame(height: 194)
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            
            pageControl
                .padding(.top, 12)

        }

    }
    
    //MARK: Page Control
    private var pageControl: some View {
        HStack(spacing: 4) {
            ForEach(0..<homeVM.userData.projectsDTOs.count, id: \.self) { index in
                Circle()
                    .frame(width: 6, height: 6)
                    .foregroundColor(index == currentPage ? .theme.mainPurpleColor : .init(hex: "D9D9D9"))
            }
        }
        .frame(height: 6)
        .padding(.horizontal, 16)
    }
}

// MARK: Progress Bar Style
/// ProgressView의 스타일을 커스터마이징하는 구조체입니다.
/// 기존 코드를 활용하여 배경과 진행바의 색깔과 크기 위치를 설정하였습니다.
/// 기존의 폭탄 아이콘도 상태진행에 따라 끝부분에서 움직이도록 설정하였습니다.
struct CustomProgressViewStyle: ProgressViewStyle {
    func makeBody(configuration: Configuration) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                
                // Default Background
                Capsule()
                    .fill(Color.black.opacity(0.08))
                    .frame(height: 8)
                
                // Progress Background
                Capsule()
                    .fill(Color.theme.mainPurpleColor)
                    .frame(width: geometry.size.width * CGFloat(configuration.fractionCompleted ?? 0), height: 8)
                
                // Trail Icon
                if let fractionCompleted = configuration.fractionCompleted {
                    Image("bomb_smile")
                        .offset(x: geometry.size.width * CGFloat(fractionCompleted) - 12)
                }
            }
        }
    }
}


//struct MyProjectView_Previews: PreviewProvider {
//    static var previews: some View {
//        MyProjectView(isProjectExist: .constant(false))
//    }
//}
