//
//  ProjectDTO.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/08/25.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation

//============================
// MARK: Card - Home/Project
//============================
/// Service -> View/ViewModel
struct ProjectCardDTO{
    // content
    let title: String
    
    // status
    let startedAt: Date
    let deadline: Date
    let finished: Bool
    
    // todo
    let registedTodo: Int
    let finishedTodo: Int
    
    
    // Constructor
    // Coredata
    init(from projectEntity: ProjectEntity){
        self.title = projectEntity.proj_title ?? ""
        self.startedAt = projectEntity.proj_started_at ?? Date()
        self.deadline = projectEntity.proj_deadline ?? Date()
        self.finished = projectEntity.proj_finished
        self.registedTodo = Int(projectEntity.proj_todo_registed)
        self.finishedTodo = Int(projectEntity.proj_todo_finished)
    }
    
    // dummyTest
    init(from projectObject: ProjectObject){
        self.title = projectObject.proj_title
        self.startedAt = projectObject.proj_started_at
        self.deadline = projectObject.proj_deadline
        self.finished = projectObject.proj_finished
        self.registedTodo = Int(projectObject.proj_todo_registed)
        self.finishedTodo = Int(projectObject.proj_todo_finished)
    }
}

//============================
// MARK: Set - Project
//============================
struct ProjectSetDTO{
    // content
    let title: String
    
    // status
    let startedAt: Date
    let deadline: Date
    
    // Constructor
    init(title: String, startedAt: Date, deadline: Date) {
        self.title = title
        self.startedAt = startedAt
        self.deadline = deadline
    }
}

//============================
// MARK: Update - Project
//============================
struct ProjectUpdateDTO{
    // id
    var userId: String?
    var projectId: Int?
    var todoId: Int?
    
    // content
    var newTitle: String?
    var newDeadline: Date?
    
    // Todo
    var todo: TodoObject?
    var todoStatus: Bool?
    
    init(to newDeadLine: Date){
        self.newDeadline = newDeadLine
    }
    
    init(to newTitle: String){
        self.newTitle = newTitle
    }
}

