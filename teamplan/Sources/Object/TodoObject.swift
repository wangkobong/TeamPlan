//
//  TodoObject.swift
//  teamplan
//
//  Created by 주찬혁 on 1/3/24.
//  Copyright © 2024 team1os. All rights reserved.
//

import Foundation

struct TodoObject{
    
    let projectId: Int
    let todoId: Int
    let userId: String
    let desc: String
    let pinned: Bool
    let status: TodoStatus
    
    init(projectId: Int, todoId: Int, userId: String, desc: String, pinned: Bool, status: TodoStatus) {
        self.projectId = projectId
        self.todoId = todoId
        self.userId = userId
        self.desc = desc
        self.pinned = pinned
        self.status = status
    }
}

enum TodoStatus: Int {
    case ongoing = 0
    case finish = 1
}
