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
    let period: Int
    let startAt: Date
    let deadline: Date
    var alert: Int
    var complete: Bool
    var todoRegist: Int
    var todoFinish: Int
    var todoRemain: Int
    let todoLimit: Int
    var todoList: [TodoListDTO] = []
    
    //--------------------
    // constructor
    //--------------------
    // Default
    init(){
        self.userId = ""
        self.projectId = 0
        self.title = ""
        self.period = 0
        self.startAt = Date()
        self.deadline = Date()
        self.alert = 0
        self.complete = false
        self.todoRegist = 0
        self.todoFinish = 0
        self.todoLimit = 0
        self.todoRemain = 0
    }
    // Ready Service
    init(with object: ProjectObject,
         period: Int, limit: Int){
        self.userId = object.proj_user_id
        self.projectId = object.proj_id
        self.title = object.proj_title
        self.period = period
        self.startAt = object.proj_started_at
        self.deadline = object.proj_deadline
        self.alert = object.proj_alerted
        self.complete = object.proj_finished
        self.todoRegist = object.proj_todo_registed
        self.todoFinish = object.proj_todo_finished
        self.todoRemain = self.todoRegist - self.todoFinish
        self.todoLimit = limit
    }
    
    //--------------------
    // function
    //--------------------
    mutating func updateProjectComplete(with newStatus: Bool){
        self.complete = newStatus
    }
    
    mutating func updateTodoRegist(with newVal: Int){
        self.todoRegist = newVal
        updateTodoRemain()
    }
    
    mutating func updateTodoFinish(with newVal: Int){
        self.todoFinish = newVal
        updateTodoRemain()
    }
    
    mutating func updateTodoRemain() {
        self.todoRemain = self.todoRegist - self.todoFinish
    }
    
    mutating func updateAlert(with newVal: Int) {
        self.alert = newVal
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
    let newTitle: String?
    let newDeadline: Date?
    let newAlerted: Int?
    let newStatus: Bool?
    let newTodoRegist: Int?
    let newTodoFinish: Int?
    
    //--------------------
    // constructor
    //--------------------
    // ProjectIndex
    init(userId: String, projectId: Int,
         newTitle: String? = nil,
         newStatus: Bool? = nil,
         newDeadLine: Date? = nil,
         newAlerted: Int? = nil,
         newTodoRegist: Int? = nil,
         newTodoFinish: Int? = nil
    ){
        self.userId = userId
        self.projectId = projectId
        self.newTitle = newTitle
        self.newStatus = newStatus
        self.newDeadline = newDeadLine
        self.newAlerted = newAlerted
        self.newTodoRegist = newTodoRegist
        self.newTodoFinish = newTodoFinish
    }
}

//============================
// MARK: Card for ViewModel
//============================
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
    init?(entity: ProjectEntity){
        guard let title = entity.proj_title,
              let startedAt = entity.proj_started_at,
              let deadline = entity.proj_deadline
        else {
            return nil
        }
        // Assign Value
        self.title = title
        self.startedAt = startedAt
        self.deadline = deadline
        self.finished = entity.proj_finished
        self.registedTodo = Int(entity.proj_todo_registed)
        self.finishedTodo = Int(entity.proj_todo_finished)
    }
}
