//
//  MyProjectCardView.swift
//  teamplan
//
//  Created by sungyeon on 6/3/24.
//  Copyright © 2024 team1os. All rights reserved.
//

import SwiftUI

struct MyProjectCardView: View {
    let stat: StatDTO
    let project: ProjectHomeDTO
    let percent: CGFloat = 0.65
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                projectHead
                projectTitle
                projectTodoCount
                Spacer().frame(height: 35)
                projectProgressBar
                    .padding(.bottom, 16)
                projectDeadline
            }
            .padding(.horizontal, 16)
            .frame(height: 192)
            .frame(maxWidth: .infinity)
            .clipped()
            .background(
                Rectangle()
                    .foregroundColor(.clear)
                    .frame(width: geometry.size.width * 0.9, height: 192)
                    .background(.white)
                    .cornerRadius(8)
                    .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 0)
            )
            .padding(.horizontal, geometry.size.width * 0.07)
        }
        .frame(height: 192) // 카드의 높이를 고정
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
            Text("총 \(project.remainTodo)개의 할 일이 남아있어요")
                .font(.appleSDGothicNeo(.regular, size: 12))
                .foregroundColor(.black)
            Spacer()
        }
    }
    
    //MARK: Progress Bar
    
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
                Spacer()
                Text(project.remainDay < 0 ? "기간만료" : "D-\(project.remainDay)")
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

//#Preview {
//    MyProjectCardView()
//}
