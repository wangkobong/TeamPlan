//
//  ProjectDTO.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/08/25.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation

//============================
// MARK: Home - Local
//============================
/// Service -> View/ViewModel
struct ProjectHomeLocalResDTO{
    // content
    let proj_title: String
    
    // status
    let proj_started_at: Date
    let proj_deadline: Date
    let proj_finished: Bool
    
    // todo
    let proj_todo_registed: Int
    let proj_todo_finished: Int
    
    
    // Constructor
    // Coredata
    init(from projectEntity: ProjectEntity){
        self.proj_title = projectEntity.proj_title ?? ""
        self.proj_started_at = projectEntity.proj_started_at ?? Date()
        self.proj_deadline = projectEntity.proj_deadline ?? Date()
        self.proj_finished = projectEntity.proj_finished
        self.proj_todo_registed = Int(projectEntity.proj_todo_registed)
        self.proj_todo_finished = Int(projectEntity.proj_todo_finished)
    }
    
    // dummyTest
    init(from projectObject: ProjectObject){
        self.proj_title = projectObject.proj_title
        self.proj_started_at = projectObject.proj_started_at
        self.proj_deadline = projectObject.proj_deadline
        self.proj_finished = projectObject.proj_finished
        self.proj_todo_registed = Int(projectObject.proj_todo_registed)
        self.proj_todo_finished = Int(projectObject.proj_todo_finished)
    }
}
