//
//  ProjectMainView.swift
//  teamplan
//
//  Created by sungyeon on 2024/02/01.
//  Copyright © 2024 team1os. All rights reserved.
//

import SwiftUI

enum ProjectViewType {
    case projectDetail
}

struct ProjectMainView: View {
    
    @ObservedObject var projectViewModel: ProjectViewModel
    
    @State private var isProjectListEmpty = false
    @State private var isAddProjectViewActive = false
    @State private var isPushProjectDetailView = false
    @State private var showAlert: Bool = false
    
    @State var path: [ProjectViewType] = []
    @State var projectDetailViewIndex = 0
    
    var body: some View {
        Group {
            if isProjectListEmpty {
                ProjectEmptyView(projectViewModel: projectViewModel)
            } else {
                ScrollView {
                    VStack {
                        NavigationLink(
                            destination: ProjectDetailView(
                                projectViewModel: projectViewModel,
                                project: $projectViewModel.projectList[projectDetailViewIndex]),
                            isActive: $isPushProjectDetailView) {
                        }
                        .opacity(0)
                        
                        userNameArea
                        
                        Spacer()
                            .frame(height: 15)
                        
                        informationArea
                        
                        Spacer()
                            .frame(height: 15)
                        
                        projectsArea

                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .sheet(isPresented: $isAddProjectViewActive) {
                        AddProjectView(projectViewModel: projectViewModel)
                    }
                }
                .onAppear {
                    checkIndex()
                    checkArray()
                }
                .onChange(of: projectViewModel.isProjectRemoved) { newValue in
                    if newValue {
                        adjustArray()
                        checkIndex()
                        checkArray()
                    }
                }
                .alert(isPresented: $showAlert) {
                    Alert(
                        title: Text("목표등록 수 초과"),
                        message: Text("최대 등록가능한 목표는 \(projectViewModel.projectRegistLimit)개 입니다."),
                        dismissButton: .default(Text("확인"))
                    )
                }
            }
        }
    }
}

extension ProjectMainView {
 
    func checkIndex() {
        if projectDetailViewIndex >= projectViewModel.projectList.count {
            projectDetailViewIndex = max(0, projectViewModel.projectList.count - 1)
        }
    }
    
    func checkArray() {
        isProjectListEmpty = projectViewModel.projectList.isEmpty
    }
    
    func adjustArray() {
        projectViewModel.updateProjectList()
        projectViewModel.isProjectRemoved = false
    }
}

extension ProjectMainView {
    private var userNameArea: some View {
        HStack {
            VStack(alignment: .leading) {
                HStack {
                    Text("\(projectViewModel.userName)" + "님,    ")
                        .font(.appleSDGothicNeo(.bold, size: 20))
                        .foregroundColor(.theme.blackColor)
                        .background(
                            Color.init(hex: "7248E1").opacity(0.5)
                                .frame(height: 3)
                                .offset(y: 7)
                        )
                    Spacer()
                }
                HStack {
                    Text("\(projectViewModel.projectList.count)개의 프로젝트가 있어요")
                        .font(.appleSDGothicNeo(.bold, size: 20))
                        .foregroundColor(.theme.blackColor)
                    Spacer()
                }
            }
            
            HStack() {
                Image(systemName: "plus")
                    .foregroundColor(.theme.mainPurpleColor)
                    .imageScale(.small)
                Text("목표")
                    .font(.appleSDGothicNeo(.semiBold, size: 14))
                    .foregroundColor(.theme.mainPurpleColor)
                    .offset(x: -3)
                
            }
            .frame(width: 93, height: 36)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(SwiftUI.Color.theme.mainPurpleColor, lineWidth: 1)
            )
            .offset(x: 0)
            .onTapGesture {
                if projectViewModel.projectList.count < 5 {
                    isAddProjectViewActive.toggle()
                } else {
                    self.showAlert = true
                }
            }
        }
    }
    
    private var informationArea: some View {
        HStack {
            
            let width = (UIScreen.main.bounds.width - 39) / 3
            HStack(alignment: .center) {
                Spacer()
                VStack {
                    Text("등록했던 모든 목표")
                        .font(.appleSDGothicNeo(.semiBold, size: 12))
                        .foregroundColor(.theme.blackColor)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                        .padding(.top, 11)
                    Spacer()
                    Text("\(projectViewModel.statData.totalRegistedProjects)")
                        .font(.appleSDGothicNeo(.bold, size: 18))
                        .foregroundColor(.theme.mainPurpleColor)
                        .padding(.bottom, 14)
                }
                
                Spacer()
                
                Divider()
                    .padding(.top, 7)
                    .padding(.bottom, 7)

                Spacer()
                
                VStack {
                    Text("완료했던 모든 목표")
                        .font(.appleSDGothicNeo(.semiBold, size: 12))
                        .foregroundColor(.theme.blackColor)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                        .padding(.top, 11)
                    Spacer()
                    Text("\(projectViewModel.statData.totalFinishedProjects)")
                        .font(.appleSDGothicNeo(.bold, size: 18))
                        .foregroundColor(.theme.mainPurpleColor)
                        .padding(.bottom, 14)
                }
     
                Spacer()
            }
            .frame(width: width * 2)
            .background(Color.white)
            .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)

            Spacer()
            
            VStack {
                VStack {
                    Text("물방울 개수")
                        .font(.appleSDGothicNeo(.semiBold, size: 12))
                        .foregroundColor(.theme.blackColor)
                        .padding(.top, 11)
                    Spacer()
                    Text("\(projectViewModel.statData.drop)")
                        .font(.appleSDGothicNeo(.bold, size: 18))
                        .foregroundColor(.theme.mainBlueColor)
                        .padding(.bottom, 14)
                }
            }
            .frame(width: width)
            .background(Color.white)
            .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
            .padding(.leading, 7)
        }
        .frame(height: 78)
    }
    
    private var projectsArea: some View {
        VStack {
            ForEach(projectViewModel.projectList.indices, id: \.self) { index in
                ProjectCardView(project: $projectViewModel.projectList[index], projectViewModel: projectViewModel)
                    .onTapGesture {
                        projectDetailViewIndex = index
                        isPushProjectDetailView.toggle()
                    }
            }
        }
    }
}

struct ProjectMainView_Previews: PreviewProvider {
    static var previews: some View {
        ProjectMainView(projectViewModel: ProjectViewModel())
    }
}
