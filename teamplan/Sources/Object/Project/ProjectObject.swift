//
//  ProjectObject.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/08/25.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation

//============================
// MARK: Project Entity
//============================
struct ProjectObject{
    
    //--------------------
    // Content
    //--------------------
    // id
    let proj_id: Int
    let proj_user_id: String
    
    // content
    let proj_title: String
    
    // status
    let proj_started_at: Date
    let proj_deadline: Date
    let proj_finished: Bool
    
    // todo
    let proj_todo: [TodoObject]
    let proj_todo_registed: Int
    let proj_todo_finished: Int
    
    // Maintenance
    let proj_registed_at: Date
    let proj_changed_at: Date
    var proj_finished_at: Date?
    
    //--------------------
    // Constructor
    //--------------------
    init(from dto: ProjectSetDTO, id: Int, userId: String) {
        let setDate = Date()
        self.proj_id = id
        self.proj_user_id = userId
        self.proj_title = dto.title
        self.proj_started_at = dto.startedAt
        self.proj_deadline = dto.deadline
        self.proj_finished = false
        self.proj_todo = []
        self.proj_todo_registed = 0
        self.proj_todo_finished = 0
        self.proj_registed_at = setDate
        self.proj_changed_at = setDate
    }
    
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
}

//============================
// MARK: Todo Entity
//============================
struct TodoObject{
    
    //--------------------
    // Content
    //--------------------
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
    
    //--------------------
    // Constructor
    //--------------------
    init(todoEntity: TodoEntity){
        self.todo_id = Int(todoEntity.todo_id)
        self.todo_desc = todoEntity.todo_desc ?? "Unknown"
        self.todo_pinned = todoEntity.todo_pinned
        self.todo_status = todoEntity.todo_status
        self.todo_registed_at = todoEntity.todo_registed_at ?? Date()
        self.todo_changed_at = todoEntity.todo_changed_at ?? Date()
        self.todo_updated_at = todoEntity.todo_updated_at ?? Date()
    }
}
