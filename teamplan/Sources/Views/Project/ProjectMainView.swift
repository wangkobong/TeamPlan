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
    
    @StateObject var projectViewModel = ProjectViewModel()
    
    @State private var isAddProjectViewActive = false
    @State private var isPushProjectDetailView = false
    
    @State var path: [ProjectViewType] = []
    @State var projectDetailViewIndex = 0
    
    var body: some View {
        ScrollView {
            VStack {
                NavigationLink(
                    destination: ProjectDetailView(index: projectDetailViewIndex)
                        .environmentObject(projectViewModel),
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
                AddProjectView()
            }
        }

    }
}

struct ProjectMainView_Previews: PreviewProvider {
    static var previews: some View {
        ProjectMainView()
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
                    Text("3개의 프로젝트가 있어요")
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
                isAddProjectViewActive.toggle()
            }
        }

    }
    
    private var informationArea: some View {
        HStack {
            
            let width = (UIScreen.main.bounds.width - 39) / 3
            HStack(alignment: .center) {
                Spacer()
                VStack {
                    Text("등록 프로젝트")
                        .font(.appleSDGothicNeo(.semiBold, size: 12))
                        .foregroundColor(.theme.blackColor)
                        .padding(.top, 11)
                    Spacer()
                    Text("3")
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
                    Text("완료 프로젝트")
                        .font(.appleSDGothicNeo(.semiBold, size: 12))
                        .foregroundColor(.theme.blackColor)
                        .padding(.top, 11)
                    Spacer()
                    Text("12")
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
                    Text("10")
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
            VStack {
                ForEach(Array(projectViewModel.projects.enumerated()), id: \.1.id) { index, project in
                    ProjectCardView(project: project)
                        .onTapGesture {
                            projectDetailViewIndex = index
                            isPushProjectDetailView.toggle()
                            print("Index: \(index)")
                        }
                }
            }
        }
    }
}
