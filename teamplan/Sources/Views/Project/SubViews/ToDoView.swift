//
//  ToDoView.swift
//  teamplan
//
//  Created by sungyeon kim on 2024/02/24.
//  Copyright © 2024 team1os. All rights reserved.
//

import SwiftUI

struct ToDoView: View {
    @ObservedObject var projectViewModel: ProjectViewModel
    @Binding var toDo: TodoDTO
    @State private var isEditing: Bool = false
    @State private var showAlert: Bool = false
    @State private var tempDesc: String = ""
    let projectId: Int
    
    var body: some View {
        HStack {
            HStack {
                Image(toDo.status == .finish ? "checkBox_done" : "checkBox_none")
                    .onTapGesture {
                        if toDo.desc != "" {
                            projectViewModel.toggleToDoStatus(with: projectId, todoId: toDo.todoId, newStatus: toDo.status == .finish ? .ongoing : .finish)
                        }
                    }
                ZStack {
                    TextField(getPlaceholder(), text: $tempDesc) { editing in
                        self.isEditing = editing
                    }
                    .padding(.horizontal, 16)
                    .font(.appleSDGothicNeo(.regular, size: 14))
                    .background(
                        Color.black
                            .frame(height: 1)
                            .padding(.horizontal, 10)
                            .opacity(toDo.status == .finish ? 1 : 0)
                    )
                    .disabled(toDo.status == .finish ? true : false)
                    .onSubmit {
                        if tempDesc.count > 20 {
                            showAlert = true
                            tempDesc = String(tempDesc.prefix(20))
                        }
                        toDo.desc = tempDesc
                        if toDo.desc != "" {
                            projectViewModel.updateTodoDescription(
                                with: projectId, todoId: toDo.todoId, newDesc: toDo.desc
                            )
                        }
                    }

                    RoundedRectangle(cornerRadius: 24)
                        .stroke(isEditing ? SwiftUI.Color.theme.mainPurpleColor : Color(hex: "E2E2E2"), lineWidth: 1)
                }
                .frame(height: 38)
                .frame(maxWidth: .infinity)
            }
            
            Spacer()
        }
        .onAppear {
            tempDesc = toDo.desc
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("글자 수 초과"),
                message: Text("공백을 포함한 글자 수는 최대 20자입니다."),
                dismissButton: .default(Text("확인"))
            )
        }
    }
}
//struct ToDoView_Previews: PreviewProvider {
//    static var previews: some View {
//        ToDoView(toDo: Todo)
//    }
//}

extension ToDoView {
    private func getPlaceholder() -> String {
        return toDo.desc.isEmpty ? "할 일은 삭제가 불가능하지만 수정은 가능해요" : toDo.desc
    }
}
