//
//  ProjectDTO.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/08/25.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation

//============================
// MARK: Info
//============================
// ProjectDetailService
struct ProjectDetailDTO{
    
    //--------------------
    // content
    //--------------------
    let userId: String
    let projectId: Int
    let title: String
    let startAt: Date
    let deadline: Date
    let period: Int
    let todoLimit: Int
    var todoRegisted: Int
    var todoList: [TodoInfo] = []
    
    //--------------------
    // constructor
    //--------------------
    // Default
    init(){
        self.userId = ""
        self.projectId = 0
        self.title = ""
        self.startAt = Date()
        self.deadline = Date()
        self.period = 0
        self.todoRegisted = 0
        self.todoLimit = 0
    }
    // Ready Service
    init(with object: ProjectObject, period: Int, limit: Int){
        self.userId = object.proj_user_id
        self.projectId = object.proj_id
        self.title = object.proj_title
        self.startAt = object.proj_started_at
        self.deadline = object.proj_deadline
        self.period = period
        self.todoRegisted = object.proj_todo_registed
        self.todoLimit = limit
    }
    
    //--------------------
    // function
    //--------------------
    mutating func updateTodoRegist(with newVal: Int){
        self.todoRegisted = newVal
    }
}

//============================
// MARK: Set
//============================
// ProjectIndexService
struct ProjectSetDTO{
    
    //--------------------
    // content
    //--------------------
    let title: String
    let startedAt: Date
    let deadline: Date
    
    //--------------------
    // constructor
    //--------------------
    init(title: String, startedAt: Date, deadline: Date) {
        self.title = title
        self.startedAt = startedAt
        self.deadline = deadline
    }
}

//============================
// MARK: Update
//============================
// ProjectCoredataService
struct ProjectUpdateDTO{
    
    //--------------------
    // content
    //--------------------
    let userId: String
    let projectId: Int
    var newTitle: String?
    var newDeadline: Date?
    var newTodoRegist: Int?
    
    //--------------------
    // constructor
    //--------------------
    // ProjectIndex
    init(with userId: String, and projectId: Int, to newDeadLine: Date){
        self.userId = userId
        self.projectId = projectId
        self.newDeadline = newDeadLine
    }
    // ProjectDetail
    init(with data: ProjectDetailDTO){
        self.userId = data.userId
        self.projectId = data.projectId
        self.newTodoRegist = data.todoRegisted
    }
}

//============================
// MARK: toViewModel
//============================
/// * Page Service => ViewModel
/// * Struct for Home / ProjectIndex Page, Project Card Info
struct ProjectCardDTO{
    
    //--------------------
    // content
    //--------------------
    let title: String
    let startedAt: Date
    let deadline: Date
    let finished: Bool
    let registedTodo: Int
    let finishedTodo: Int
    
    //--------------------
    // constructor
    //--------------------
    // Coredata
    init(from projectEntity: ProjectEntity){
        self.title = projectEntity.proj_title ?? ""
        self.startedAt = projectEntity.proj_started_at ?? Date()
        self.deadline = projectEntity.proj_deadline ?? Date()
        self.finished = projectEntity.proj_finished
        self.registedTodo = Int(projectEntity.proj_todo_registed)
        self.finishedTodo = Int(projectEntity.proj_todo_finished)
    }
}
