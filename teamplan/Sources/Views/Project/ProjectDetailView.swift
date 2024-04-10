//
//  ProjectDetailView.swift
//  teamplan
//
//  Created by sungyeon on 2024/02/19.
//  Copyright © 2024 team1os. All rights reserved.
//

import SwiftUI

struct ProjectDetailView: View {
    
    @Environment(\.dismiss) var dismiss
    @ObservedObject var projectViewModel: ProjectViewModel
    
    @Binding var project: ProjectDTO
    
    @State private var isShowAddToDo: Bool = false
    @State private var isShowEmptyView: Bool = true
    @State private var isAdding: Bool = false
    @State private var isPresented: Bool = false
    
    var body: some View {
        VStack {
            header
            
            Divider()
                .padding(.horizontal, 16)
            
            contents
            
            button
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {

                Button {
                    dismiss.callAsFunction()
                    
                } label: {
                    Image("left_arrow_home")
                }
            }
        }
        .navigationTitle("\(project.title)")
        .navigationBarBackButtonHidden(true)
        .onAppear {

        }
        .projectCompleteAlert(isPresented: $isPresented) {
            ProjectCompleteAlertView(isPresented: $isPresented) {
                Task {
                    await self.completeProject()
                }
            }
        }
    }
}

//struct ProjectDetailView_Previews: PreviewProvider {
//    static var previews: some View {
//        ProjectDetailView(index: 0)
//    }
//}

extension ProjectDetailView {
    private var header: some View {
        ZStack{
            VStack(alignment: .leading) {
                Text("D-\(project.deadline.days(from: Date()))")
                    .foregroundColor(Color.theme.mainPurpleColor)
                    .font(.appleSDGothicNeo(.bold, size: 24))
                    .padding(.bottom, 5)
                
                HStack {
                    Text("\(project.startAt.fullCheckDay)")
                    Text("~")
                    Text("\(project.deadline.fullCheckDay)")
                }
                .foregroundColor(Color.theme.mainBlueColor)
                .font(.appleSDGothicNeo(.regular, size: 12))
     
                HStack {
                    Text("할 일을 추가해주세요!")
                        .font(.appleSDGothicNeo(.bold, size: 17))
                        .foregroundColor(.theme.darkGreyColor)
                        .background(
                            Color.init(hex: "7248E1").opacity(0.5)
                                .frame(height: 3)
                                .offset(y: 7)
                        )
                    Spacer()
                }
                .padding(.bottom, 1)
                
                Text("오늘, 추가할 수 있는 할 일은 \(project.todoCanRegist)개 남았어요")
                    .font(.appleSDGothicNeo(.regular, size: 14))
                    .foregroundColor(.theme.darkGreyColor)
                
                Spacer()
                    .frame(height: 20)
            }
            
            HStack {
                Spacer()
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isAvailableAddingToDo() ? ColorTheme().mainPurpleColor : .clear, lineWidth: 1)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(isAvailableAddingToDo() ? .clear : Color(hex: "E5E5E5"))
                        )
                    
                    HStack {
                        Image(systemName: "plus")
                            .foregroundColor(isAvailableAddingToDo() ? .theme.mainPurpleColor : Color.theme.greyColor)
                            .imageScale(.small)
                        Text("할 일")
                            .font(.appleSDGothicNeo(.semiBold, size: 14))
                            .foregroundColor(isAvailableAddingToDo() ? .theme.mainPurpleColor : Color.theme.greyColor)
                            .offset(x: -3)
                    }
                }
                .frame(width: 72, height: 38)
                .onTapGesture {
                    if isAvailableAddingToDo() {
                        self.addTodo()
                    }
                }
            }
        }
        .padding(.leading, 38)
        .padding(.trailing, 24)

    }
    
    private var contents: some View {
        ZStack{
            if !project.todoList.isEmpty {
                ScrollView {
                    Spacer()
                        .frame(height: 25)
                    VStack(spacing: 8) {
                        ForEach(Array(project.todoList.enumerated()), id: \.1.todoId) { index, toDo in
                            ToDoView(projectViewModel: projectViewModel, toDo: $project.todoList[index], projectId: project.projectId)
                        }
                    }
                }
            } else {
                VStack {
                    Spacer()
                    projectEmpty
                    Spacer()
                }
            }
        }
        .padding(.leading, 38)
        .padding(.trailing, 24)

    }
    
    private var projectEmpty: some View {
        VStack {
            
            Image("project_empty")
                .frame(width: 67, height: 68.5)
                .padding(.bottom, 10)
            
            HStack {
                Text("할 일이")
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
            
            
            Text("얼른 할 일을 추가해보세요")
                .font(.appleSDGothicNeo(.regular, size: 16))
                .foregroundColor(.theme.blackColor)
        }

    }
    
    private var button: some View {
        
        VStack {
            Divider()
                .padding(.bottom, 13)
                .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 2)
            
            
            Text("프로젝트 완료하기")
                .foregroundColor(.white)
                .frame(height: 48)
                .frame(maxWidth: .infinity)
                .background(isCompletedToDo() ? Color.theme.mainPurpleColor : Color.theme.greyColor)
                .cornerRadius(8)
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                .onTapGesture {
                    if isCompletedToDo() {
                        self.showProjectDonePopup()
                    }
                }
        }
    }
}


extension ProjectDetailView {
    private func addTodo() {
        withAnimation(.spring()) {
            self.projectViewModel.addNewTodo(projectId: self.project.projectId)
            self.isShowEmptyView = false
        }
    }
    
    private func isCompletedToDo() -> Bool {
        return project.todoList.count > 0 && project.todoList.allSatisfy { $0.status == .finish }
    }
    
    private func completeProject() async {
        await projectViewModel.completeProject(with: project.projectId)
        dismiss.callAsFunction()
    }
    
    private func isAvailableAddingToDo() -> Bool {
        return project.todoCanRegist == 0 ? false : true
    }
    
    private func showProjectDonePopup() {
        self.isPresented = true
    }
}
