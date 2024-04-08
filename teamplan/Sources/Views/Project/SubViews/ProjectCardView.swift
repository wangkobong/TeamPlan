//
//  ProjectCardView.swift
//  teamplan
//
//  Created by sungyeon on 2024/02/01.
//  Copyright © 2024 team1os. All rights reserved.
//

import SwiftUI

struct ProjectCardView: View {
    
    @ObservedObject var projectViewModel: ProjectViewModel
    @Binding var project: ProjectDTO
    var body: some View {
        VStack {
            Spacer()
                .frame(height: 18)
            HStack {
                VStack(alignment: .leading) {
                    Text(project.title)
                        .font(.appleSDGothicNeo(.bold, size: 17))
                        .foregroundColor(.theme.blackColor)

                    HStack {
                        Text("\(project.todoList.count)개의 투두")
                            .font(.appleSDGothicNeo(.semiBold, size: 12))
                            .foregroundColor(.theme.darkGreyColor)
                        Text("가 남아있어요")
                            .font(.appleSDGothicNeo(.light, size: 12))
                            .foregroundColor(Color(hex: "3B3B3B"))
                            .offset(x: -8)
                    }

                }
                Spacer()
                
                Menu {
                    Button("삭제", action: {
                        projectViewModel.deleteProject(projectId: project.projectId)
                    })
                    Button("수정 및 기한 연장", action: {
                     
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
            
            Spacer()
                .frame(height: 10)
            
            VStack {
                ZStack(alignment: .leading) {
                    
                    ZStack(alignment: .trailing) {
                        Capsule()
                            .fill(Color(hex: "D9D9D9"))
                            .frame(height: 8)
                    }
                    Capsule()
                        .fill(
                            Color.theme.mainPurpleColor
                        )
                        .frame(width: calculateGraphWidth(
                            remainingDays: project.deadline.days(from: Date()),
                            totalDays: project.deadline.days(from: project.startAt)),
                               height: 8)

                    
                    Image("project_bomb_smile")
                        .offset(x: calculateGraphWidth(
                            remainingDays: project.deadline.days(from: Date()),
                            totalDays: project.deadline.days(from: project.startAt)) - 10
                        )
                }
                
                HStack {
                    Spacer()
                    Text("D-\(project.deadline.days(from: Date()))")
                        .font(.appleSDGothicNeo(.regular, size: 12))
                        .foregroundColor(.theme.blackColor)
                }
                .offset(y: -8)
            }
            .padding(.leading, 20)
            .padding(.trailing, 20)
            
            Spacer()
                .frame(height: 17)
        }
        .frame(height: 133)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
        )
        
    }
}

//struct ProjectCardView_Previews: PreviewProvider {
//    static var previews: some View {
//        ProjectCardView()
//            .previewLayout(.sizeThatFits)
//    }
//}


extension ProjectCardView {
    func calculateGraphWidth(remainingDays: Int, totalDays: Int) -> CGFloat {
        
        let barWidth = UIScreen.main.bounds.size.width - 32 - 40
        let remainingDaysFloat = CGFloat(remainingDays)
        let totalDaysFloat = CGFloat(totalDays)
        return (remainingDaysFloat / totalDaysFloat) * barWidth
    }
}
