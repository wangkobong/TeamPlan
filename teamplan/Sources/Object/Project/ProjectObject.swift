//
//  ProjectObject.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/08/25.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation

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
    let proj_alerted: Int
    
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
    // Set
    init(from dto: ProjectSetDTO, id: Int, userId: String, at setDate: Date) {
        self.proj_id = id
        self.proj_user_id = userId
        self.proj_title = dto.title
        self.proj_started_at = dto.startedAt
        self.proj_deadline = dto.deadline
        self.proj_finished = false
        self.proj_alerted = 0
        self.proj_todo = []
        self.proj_todo_registed = 0
        self.proj_todo_finished = 0
        self.proj_registed_at = setDate
        self.proj_changed_at = setDate
    }
    // CoreData
    init?(entity: ProjectEntity){
        guard let userId = entity.proj_user_id,
              let title = entity.proj_title,
              let startedAt = entity.proj_started_at,
              let deadline = entity.proj_deadline,
              let registedAt = entity.proj_registed_at,
              let updatedAt = entity.proj_changed_at,
              let finishedAt = entity.proj_finished_at,
              let todoEntities = entity.todo_relationship as? Set<TodoEntity>
        else {
            return nil
        }
        let todoList = todoEntities.compactMap { TodoObject(with: $0) }

        // Assigning values
        self.proj_id = Int(entity.proj_id)
        self.proj_user_id = userId
        self.proj_title = title
        self.proj_started_at = startedAt
        self.proj_deadline = deadline
        self.proj_finished = entity.proj_finished
        self.proj_alerted = Int(entity.proj_alerted)
        self.proj_todo_registed = Int(entity.proj_todo_registed)
        self.proj_todo_finished = Int(entity.proj_todo_finished)
        self.proj_registed_at = registedAt
        self.proj_changed_at = updatedAt
        self.proj_finished_at = finishedAt
        self.proj_todo = todoList
    }
}
