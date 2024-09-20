//
//  MyProjectView.swift
//  teamplan
//
//  Created by 크로스벨 on 5/20/24.
//  Copyright © 2024 team1os. All rights reserved.
//

import SwiftUI

struct MyProjectView: View {
    
    @ObservedObject var homeVM: HomeViewModel
    @ObservedObject var projectVM: ProjectViewModel
    
    @Binding var isProjectExist: Bool
    
    @State private var showAlert = false
    @State private var percent: CGFloat = 0.65
    @State private var currentPage = 0
    @State private var isProjectCardPush = false
    @State private var isNoProjectCardPush = false
    @State private var projectCardIndex = 0
    
    var body: some View {
        VStack{
            if isProjectExist {
                projectList
                    .padding(.horizontal, 16)                    
                    .navigationDestination(isPresented: $isProjectCardPush) {
                        if projectVM.projectList.indices.contains(projectCardIndex) {
                            ProjectDetailView(
                                projectViewModel: projectVM,
                                project: $projectVM.projectList[projectCardIndex]
                            )
                        }
                    }
            } else {
                noProject
                    .padding(.horizontal, 16)
                    .navigationDestination(isPresented: $isNoProjectCardPush) {
                        AddProjectView(projectViewModel: projectVM)
                    }
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("오류"),
                message: Text("목표상세 페이지로의 진입을 실패하였습니다.\n잠시 후 다시 시도해 주세요."),
                dismissButton: .default(Text("확인"))
            )
        }
    }
    
    //MARK: Project Not Registed Bind
    private var noProject: some View {
        VStack {
            Image("warning_circle")
                .frame(width: 32, height: 32)
                .padding(.bottom, 5)
            Text("목표를 먼저 정해주세요")
                .font(.appleSDGothicNeo(.regular, size: 16))
                .padding(.bottom, 22)
            Text("목표 만들기")
                .font(.appleSDGothicNeo(.semiBold, size: 12))
                .foregroundColor(.theme.whiteColor)
                .frame(width: 111, height: 28)
                .background(Color.theme.mainPurpleColor)
                .cornerRadius(4)
                .onTapGesture {
                    self.isNoProjectCardPush = true
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
                        .onTapGesture {
                            if self.searchProjectIndex(with: project.projectId) {
                                self.isProjectCardPush = true
                            } else {
                                self.showAlert = true
                            }
                        }
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

extension MyProjectView {
    
    private func searchProjectIndex(with projectId: Int) -> Bool {
        guard let index = projectVM.projectList.firstIndex(where: { $0.projectId ==  projectId }) else {
            print("[MyProjectView] Failed to search project index at list")
            return false
        }
        self.projectCardIndex = index
        return true
    }
}

// MARK: Progress Bar Style

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
