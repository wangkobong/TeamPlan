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
    let projectId: Int
    
    var body: some View {
        HStack {
            HStack {
                Image("checkBox_none")
                    .onTapGesture {
                        print("toggle")
                    }
                ZStack {
                    TextField(toDo.desc, text: $toDo.desc) { editing in
                        self.isEditing = editing
                    }
                    .onSubmit {
                        projectViewModel.update(updateTodoDescription: projectId, todoId: toDo.todoId, newDesc: toDo.desc)
                    }
                    
                    .padding(.horizontal, 16)
                    .font(.appleSDGothicNeo(.regular, size: 14))
                    
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(isEditing ? SwiftUI.Color.theme.mainPurpleColor : Color(hex: "E2E2E2"), lineWidth: 1)
                    
                }
                .frame(height: 38)
                .frame(maxWidth: .infinity)
            }
            
            Spacer()
        }
    }
}

//struct ToDoView_Previews: PreviewProvider {
//    static var previews: some View {
//        ToDoView(toDo: Todo)
//    }
//}
