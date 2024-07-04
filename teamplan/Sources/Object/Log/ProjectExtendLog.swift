//
//  ProjectExtendLog.swift
//  teamplan
//
//  Created by 크로스벨 on 6/18/24.
//  Copyright © 2024 team1os. All rights reserved.
//

import Foundation

struct ProjectExtendLog {
    
    let projectId: Int
    let extendCount: Int
    let userId: String
    
    let usedDrop: Int
    let storedDrop: Int

    let extendPeriod: Int
    let extendAt: Date
    let newDeadline: Date
    
    let totalRegistedTodo: Int
    let totalFinshedTodo: Int
    
    init(projectId: Int, 
         extendCount: Int,
         userId: String,
         usedDrop: Int,
         storedDrop: Int,
         extendPeriod: Int,
         extendAt: Date,
         newDeadline: Date,
         totalRegistedTodo: Int, 
         totalFinshedTodo: Int
    ) {
        self.projectId = projectId
        self.extendCount = extendCount
        self.userId = userId
        self.usedDrop = usedDrop
        self.storedDrop = storedDrop
        self.extendPeriod = extendPeriod
        self.extendAt = extendAt
        self.newDeadline = newDeadline
        self.totalRegistedTodo = totalRegistedTodo
        self.totalFinshedTodo = totalFinshedTodo
    }
    
    init(day: Date = Date()) {
        self.projectId = 0
        self.extendCount = 0
        self.userId = "unknown"
        self.usedDrop = 0
        self.storedDrop = 0
        self.extendPeriod = 0
        self.extendAt = day
        self.newDeadline = day
        self.totalRegistedTodo = 0
        self.totalFinshedTodo = 0
    }
}
