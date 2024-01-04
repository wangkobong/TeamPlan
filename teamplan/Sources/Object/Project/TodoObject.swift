//
//  TodoObject.swift
//  teamplan
//
//  Created by 주찬혁 on 1/3/24.
//  Copyright © 2024 team1os. All rights reserved.
//

import Foundation

struct TodoObject{
    
    //--------------------
    // Content
    //--------------------
    // id
    let todo_id: Int
    
    // content
    let todo_desc: String
    
    // status
    let todo_pinned: Bool
    let todo_status: Bool
    
    // maintenance
    let todo_registed_at: Date
    let todo_changed_at: Date
    let todo_updated_at: Date
    
    //--------------------
    // Constructor
    //--------------------
    init?(with entity: TodoEntity){
        guard let todo_desc = entity.todo_desc,
              let todo_registed_at = entity.todo_registed_at,
              let todo_changed_at = entity.todo_changed_at,
              let todo_updated_at = entity.todo_updated_at
        else {
            return nil
        }
        self.todo_id = Int(entity.todo_id)
        self.todo_desc =  todo_desc
        self.todo_pinned = entity.todo_pinned
        self.todo_status = entity.todo_status
        self.todo_registed_at = todo_registed_at
        self.todo_changed_at = todo_changed_at
        self.todo_updated_at = todo_updated_at
    }
}
