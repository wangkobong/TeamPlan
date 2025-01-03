//
//  ProjectCardView.swift
//  teamplan
//
//  Created by sungyeon on 2024/02/01.
//  Copyright © 2024 team1os. All rights reserved.
//

import SwiftUI

struct ProjectCardView: View {
    
    @Environment(\.dismiss) var dismiss
    @Binding var project: ProjectDTO
    @ObservedObject var projectViewModel: ProjectViewModel

    @State private var isExtendProjectViewActive = false
    @State private var showDeleteAlert: Bool = false
    
    //MARK: MainBody
    
    var body: some View {
        VStack {
            headerView
                .padding(.top, 20)
            Spacer().frame(height: 20)
            progressView
            Spacer().frame(height: 10)
        }
        .frame(height: 133)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
        )
        // To Extend
        .sheet(isPresented: $isExtendProjectViewActive) {
            ProjectExtendView(projectViewModel: projectViewModel, project: $project)
        }
        // Delete Alert
        .alert(isPresented: $showDeleteAlert) {
            Alert(
                title: Text("목표삭제 실패"),
                message: Text("목표를 삭제하는 데 실패했습니다. 다시 시도해주세요."),
                dismissButton: .default(Text("확인"))
            )
        }
    }
}

extension ProjectCardView {
    
    //MARK: Header
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(project.title)
                    .font(.appleSDGothicNeo(.bold, size: 17))
                    .foregroundColor(.theme.blackColor)

                HStack {
                    Text("총 \(project.todoRemain)개의 할 일")
                        .font(.appleSDGothicNeo(.semiBold, size: 12))
                        .foregroundColor(.theme.darkGreyColor)
                    Text("이 남아있어요")
                        .font(.appleSDGothicNeo(.light, size: 12))
                        .foregroundColor(Color(hex: "3B3B3B"))
                        .offset(x: -8)
                }
            }
            Spacer()
            Menu {
                Button("삭제", action: {
                    if projectViewModel.deleteProject(projectId: project.projectId) {
                        dismiss.callAsFunction()
                    } else {
                        self.showDeleteAlert = true
                    }
                })
                Button("수정 및 기한연장", action: {
                    isExtendProjectViewActive.toggle()
                })
            } label: {
                Image("project_menu_btn")
            }
            .onTapGesture {
                // onTapGesture를 추가해서 ProjectCardView의 onTapGesture와 중복 안되게 처리
            }
        }
        .padding(.leading, 24)
        .padding(.trailing, 20)
    }

    //MARK: Progress
    
    private var progressView: some View {
        VStack {
            progressBar
                .padding(.bottom, 24)
            HStack {
                Spacer()
                Text(project.remainDays < 0 ? "기간만료" : "D-\(project.remainDays)")
                    .font(.appleSDGothicNeo(.regular, size: 12))
                    .foregroundColor(.theme.blackColor)
            }
            .offset(y: -8)
        }
        .padding(.leading, 20)
        .padding(.trailing, 20)
    }
    
    private var progressBar: some View {
        ProgressView(value: calcPercent(), total: 1.0)
            .frame(height: 8)
            .progressViewStyle(CustomProgressViewStyle())
    }
    
    private func calcPercent() -> CGFloat {
        let progress = CGFloat(project.progressedPeriod) / CGFloat(project.totalPeriod)
        return min(max(progress, 0), 1)
    }
    
}

extension ProjectCardView {
    func calculateGraphWidth(remainingDays: Int, totalDays: Int) -> CGFloat {
        
        let barWidth = UIScreen.main.bounds.size.width - 32 - 40
        let remainingDaysFloat = CGFloat(remainingDays)
        let totalDaysFloat = CGFloat(totalDays)
        return (remainingDaysFloat / totalDaysFloat) * barWidth
    }
}
