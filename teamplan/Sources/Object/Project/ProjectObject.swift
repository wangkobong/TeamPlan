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
    let proj_id: Int64
    
    // content
    var proj_title: String
    
    // status
    var proj_started_at: Date
    var proj_deadline: Date
    var proj_finished: Bool
    
    // todo
    var proj_todo: [TodoObject]
    var proj_todo_registed: Int
    var proj_todo_finished: Int
    
    // maintenance
    let proj_registed_at: Date
    var proj_changed_at: Date
    let proj_finished_at: Date
    
    // Constructor
    // Coredata
    init(projectEntity: ProjectEntity){
        self.proj_id = projectEntity.proj_id
        self.proj_title = projectEntity.proj_title ?? ""
        self.proj_started_at = projectEntity.proj_started_at ?? Date()
        self.proj_deadline = projectEntity.proj_deadline ?? Date()
        self.proj_finished = projectEntity.proj_finished
        self.proj_todo_registed = Int(projectEntity.proj_todo_registed)
        self.proj_todo_finished = Int(projectEntity.proj_todo_finished)
        self.proj_registed_at = projectEntity.proj_registed_at ?? Date()
        self.proj_changed_at = projectEntity.proj_changed_at ?? Date()
        self.proj_finished_at = projectEntity.proj_finished_at ?? Date()
                
        // Initialize the todos array
        self.proj_todo = (projectEntity.todo_relationship as? Set<TodoEntity> ?? []).map(TodoObject.init(todoEntity:))
    }
    
    // DummyTest
    init(proj_id: Int64, proj_title: String, proj_started_at: Date, proj_deadline: Date, proj_finished: Bool, proj_todo: [TodoObject], proj_todo_registed: Int, proj_todo_finished: Int, proj_registed_at: Date, proj_changed_at: Date, proj_finished_at: Date) {
        self.proj_id = proj_id
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
}

//============================
// MARK: Entity: Todo
//============================
struct TodoObject{
    // id
    let todo_id: Int64
    
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
        self.todo_id = todoEntity.todo_id
        self.todo_desc = todoEntity.todo_desc ?? ""
        self.todo_pinned = todoEntity.todo_pinned
        self.todo_status = todoEntity.todo_status
        self.todo_registed_at = todoEntity.todo_registed_at ?? Date()
        self.todo_changed_at = todoEntity.todo_changed_at ?? Date()
        self.todo_updated_at = todoEntity.todo_updated_at ?? Date()
    }
    
    // DummyTest
    init(todo_id: Int64, todo_desc: String, todo_pinned: Bool, todo_status: Bool, todo_registed_at: Date, todo_changed_at: Date, todo_updated_at: Date) {
        self.todo_id = todo_id
        self.todo_desc = todo_desc
        self.todo_pinned = todo_pinned
        self.todo_status = todo_status
        self.todo_registed_at = todo_registed_at
        self.todo_changed_at = todo_changed_at
        self.todo_updated_at = todo_updated_at
    }
}

