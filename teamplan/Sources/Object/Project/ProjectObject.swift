//
//  ProjectObject.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/08/25.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation

//============================
// MARK: Entity: Project
//============================
struct ProjectObject{
    // id
    let proj_id: Int
    let proj_user_id: String
    
    // content
    var proj_title: String
    
    // status
    var proj_started_at: Date
    var proj_deadline: Date
    var proj_finished: Bool
    
    // todo
    var proj_todo: [TodoObject]?
    var proj_todo_registed: Int = 0
    var proj_todo_finished: Int = 0

    // Maintenance
    let proj_registed_at: Date
    var proj_changed_at: Date?
    var proj_finished_at: Date?
    
    //----------------------------
    // MARK: Constructor
    //----------------------------
    // : Get
    init?(entity: ProjectEntity){
        guard let userId = entity.proj_user_id,
              let title = entity.proj_title,
              let startedAt = entity.proj_started_at,
              let deadline = entity.proj_deadline,
              let registedAt = entity.proj_registed_at,
              let updatedAt = entity.proj_changed_at,
              let finishedAt = entity.proj_finished_at,
              let todo = entity.todo_relationship as? Set<TodoEntity>
        else {
            return nil
        }
        // Assigning values
        self.proj_id = Int(entity.proj_id)
        self.proj_user_id = userId
        self.proj_title = title
        self.proj_started_at = startedAt
        self.proj_deadline = deadline
        self.proj_finished = entity.proj_finished
        self.proj_todo_registed = Int(entity.proj_todo_registed)
        self.proj_todo_finished = Int(entity.proj_todo_finished)
        self.proj_registed_at = registedAt
        self.proj_changed_at = updatedAt
        self.proj_finished_at = finishedAt
        self.proj_todo = todo.map{ TodoObject(todoEntity: $0) }
    }
    
    // : Set
    init(from dto: ProjectSetDTO, id: Int, userId: String) {
            self.proj_id = id
            self.proj_user_id = userId
            self.proj_title = dto.title
            self.proj_started_at = dto.startedAt
            self.proj_deadline = dto.deadline
            self.proj_finished = false
            self.proj_registed_at = Date()
        }
    
    // DummyTest
    init(proj_id: Int64, proj_title: String, proj_started_at: Date, proj_deadline: Date, proj_finished: Bool, proj_todo: [TodoObject], proj_todo_registed: Int, proj_todo_finished: Int, proj_registed_at: Date, proj_changed_at: Date, proj_finished_at: Date) {
        self.proj_id = Int(proj_id)
        self.proj_user_id = "Dummy"
        self.proj_title = proj_title
        self.proj_started_at = proj_started_at
        self.proj_deadline = proj_deadline
        self.proj_finished = proj_finished
        self.proj_todo = proj_todo
        self.proj_todo_registed = proj_todo_registed
        self.proj_todo_finished = proj_todo_finished
        self.proj_registed_at = proj_registed_at
        self.proj_changed_at = proj_changed_at
        self.proj_finished_at = proj_finished_at
    }
    
    //----------------------------
    // MARK: Func
    //----------------------------
    mutating func updateDeadline(to newDeadline: Date){
        self.proj_deadline = newDeadline
    }
    mutating func updateTitle(to newTitle: String){
        self.proj_title = newTitle
    }
}

//============================
// MARK: Entity: Todo
//============================
struct TodoObject{
    // id
    let todo_id: Int
    
    // content
    var todo_desc: String
    
    // status
    var todo_pinned: Bool
    var todo_status: Bool
    
    // maintenance
    let todo_registed_at: Date
    var todo_changed_at: Date
    let todo_updated_at: Date
    
    // Costructor
    // Coredata
    init(todoEntity: TodoEntity){
        self.todo_id = Int(todoEntity.todo_id)
        self.todo_desc = todoEntity.todo_desc ?? "Unknown"
        self.todo_pinned = todoEntity.todo_pinned
        self.todo_status = todoEntity.todo_status
        self.todo_registed_at = todoEntity.todo_registed_at ?? Date()
        self.todo_changed_at = todoEntity.todo_changed_at ?? Date()
        self.todo_updated_at = todoEntity.todo_updated_at ?? Date()
    }
    
    // DummyTest
    init(todo_id: Int64, todo_desc: String, todo_pinned: Bool, todo_status: Bool, todo_registed_at: Date, todo_changed_at: Date, todo_updated_at: Date) {
        self.todo_id = Int(todo_id)
        self.todo_desc = todo_desc 
        self.todo_pinned = todo_pinned
        self.todo_status = todo_status
        self.todo_registed_at = todo_registed_at
        self.todo_changed_at = todo_changed_at
        self.todo_updated_at = todo_updated_at
    }
}

