//
//  ProjectObject.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/08/25.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation

struct ProjectObject{
    
    let projectId: Int
    let userId: String
    let title: String
    let status: ProjectStatus
    let todos: [TodoObject]
    let totalRegistedTodo: Int
    let dailyRegistedTodo: Int
    let finishedTodo: Int
    let alerted: Int
    let extendedCount: Int
    let registedAt: Date
    let startedAt: Date
    let deadline: Date
    let finishedAt: Date
    let syncedAt: Date
    
    init(projectId: Int, 
         userId: String, 
         title: String,
         status: ProjectStatus,
         todos: [TodoObject],
         totalRegistedTodo: Int,
         dailyRegistedTodo: Int,
         finishedTodo: Int,
         alerted: Int,
         extendedCount: Int,
         registedAt: Date,
         startedAt: Date,
         deadline: Date,
         finishedAt: Date,
         syncedAt: Date
    ) {
        self.projectId = projectId
        self.userId = userId
        self.title = title
        self.status = status
        self.todos = todos
        self.totalRegistedTodo = totalRegistedTodo
        self.dailyRegistedTodo = dailyRegistedTodo
        self.finishedTodo = finishedTodo
        self.alerted = alerted
        self.extendedCount = extendedCount
        self.registedAt = registedAt
        self.startedAt = startedAt
        self.deadline = deadline
        self.finishedAt = finishedAt
        self.syncedAt = syncedAt
    }
    
    init(tempDate: Date = Date()){
        self.projectId = 0
        self.userId = ""
        self.title = ""
        self.status = .unknown
        self.todos = []
        self.totalRegistedTodo = 0
        self.dailyRegistedTodo = 0
        self.finishedTodo = 0
        self.alerted = 0
        self.extendedCount = 0
        self.registedAt = tempDate
        self.startedAt = tempDate
        self.deadline = tempDate
        self.finishedAt = tempDate
        self.syncedAt = tempDate
    }
    
}

enum ProjectStatus: Int {
    case ongoing = 1
    case completable = 2
    case finished = 3
    case exploded = 4
    case deleted = 5
    case unknown = 6
}
