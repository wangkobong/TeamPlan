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
    @EnvironmentObject private var homeVM: HomeViewModel
    
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
    
    //MARK: Project List & CardView
    private var projectList: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(homeVM.userData.projectsDTO.prefix(3), id: \.projectId) { project in
                    MyProjectCardView(stat: homeVM.userData.statData, project: project)
                        .frame(width: UIScreen.main.bounds.width - 32)
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

struct MyProjectCardView: View {
    let stat: StatDTO
    let project: ProjectHomeDTO
    let percent: CGFloat = 0.65
    
    var body: some View {
        VStack {
            projectHead
            projectTitle
            projectTodoCount
            Spacer().frame(height: 30)
            projectProgressBar
                .padding(.horizontal, 16)
                .padding(.bottom, 10)
            projectDeadline
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
        .padding(.horizontal, 16)
    }
    
    //MARK: Head
    
    private var projectHead: some  View {
        HStack {
            Text("마감기한이 다가오고 있어요!")
                .foregroundColor(.theme.mainPurpleColor)
                .font(.appleSDGothicNeo(.regular, size: 12))
            Spacer()
        }
    }
    
    //MARK: Title
    
    private var projectTitle: some View {
        HStack {
            Text("\(project.title)")
                .font(.appleSDGothicNeo(.bold, size: 18))
                .foregroundColor(.black)
            Spacer()
            projectWaterCount
        }
    }
    
    //MARK: WaterDrop
    
    private var projectWaterCount: some View {
        HStack {
            Image("waterdrop")
                .frame(width: 18, height: 14)
            Text("\(stat.drop)")
                .font(.appleSDGothicNeo(.semiBold, size: 18))
            Text("개")
                .font(.appleSDGothicNeo(.regular, size: 12))
                .padding(.leading, -5)
        }
    }
    
    //MARK: Todo Count
    
    private var projectTodoCount: some View {
        HStack {
            Text("총 \(project.remainTodo)개의 할 일")
                .font(.appleSDGothicNeo(.semiBold, size: 12))
                .foregroundColor(.theme.darkGreyColor)
            Text("이 남아있어요")
                .font(.appleSDGothicNeo(.light, size: 12))
                .foregroundColor(Color(hex: "3B3B3B"))
                .offset(x: -8)
            Spacer()
        }
    }
    
    //MARK: Progress Bar
    /// ios 제공하는 기본 ProgressBar 사용으로 대체하였습니다.
    /// ProgressView 는 주어진 값 (calcPercent()에 의해 계산된 값)과 총 값 (1.0)을 사용하여 진행 상태를 표시합니다.
    ///  ProgressView의 스타일은 기존 둥근형태와 폭탄 아이콘 사용을 위해 CustomProgressViewStyle 을 사용합니다.
    private var projectProgressBar: some View {
        ProgressView(value: calcPercent(), total: 1.0)
            .frame(height: 10)
            .progressViewStyle(CustomProgressViewStyle())
    }
    
    private func calcPercent() -> CGFloat {
        let progress = CGFloat(project.progressedTerm) / CGFloat(project.totalTerm)
        return min(max(progress, 0), 1)
    }
    
    //MARK: DeadLine
    
    private var projectDeadline: some View {
        VStack {
            HStack {
                Text("START")
                    .font(.appleSDGothicNeo(.regular, size: 12))
                    .foregroundColor(.theme.greyColor)
                Spacer().frame(width: 265)
                Text("D-\(project.remainDay)")
                    .font(.appleSDGothicNeo(.regular, size: 12))
                    .foregroundColor(.theme.blackColor)
            }
            Spacer().frame(height: 10)
            HStack {
                Spacer()
                Text("\(DateFormatter.shortFormatter.string(from: project.startedAt)) - \(DateFormatter.shortFormatter.string(from: project.deadline))")
                    .font(.appleSDGothicNeo(.regular, size: 12))
                    .foregroundColor(.gray)
            }
        }
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


struct MyProjectView_Previews: PreviewProvider {
    static var previews: some View {
        MyProjectView(isProjectExist: .constant(false))
    }
}
