//
//  ToDoView.swift
//  teamplan
//
//  Created by sungyeon kim on 2024/02/24.
//  Copyright © 2024 team1os. All rights reserved.
//

import SwiftUI

struct ToDoView: View {
    
    let toDo: TodoDTO
    
    var body: some View {
        HStack {
            HStack {
                Image(toDo.status.rawValue == 1 ? "checkBox_done" : "checkBox_none")
                    .onTapGesture {
                        print("toggle")
                    }
                ZStack {
                    HStack {
                        Text(toDo.desc)
                            .font(.appleSDGothicNeo(.regular, size: 14))
                            .foregroundColor(Color(hex: "1E1E1E"))
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .padding(.horizontal, 16)
                            .background(
                                Color.black
                                    .frame(height: 1)
                                    .padding(.horizontal, 10)
                                    .opacity(toDo.status.rawValue == 1 ? 1 : 0)
                            )
                        
                        Spacer()
                    }
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color(hex: "E2E2E2"), lineWidth: 1)
                    
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
