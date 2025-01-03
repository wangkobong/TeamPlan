//
//  CoreValueObject.swift
//  teamplan
//
//  Created by 크로스벨 on 3/15/24.
//  Copyright © 2024 team1os. All rights reserved.
//

import Foundation

struct CoreValueObject {
    
    let userId: String
    let projectRegistLimit: Int
    let todoRegistLimit: Int
    let dropConvertRatio: Float
    let syncCycle: Int
    
    init(userId: String, 
         projectRegistLimit: Int,
         todoRegistLimit: Int,
         dropConvertRatio: Float,
         syncCycle: Int) 
    {
        self.userId = userId
        self.projectRegistLimit = projectRegistLimit
        self.todoRegistLimit = todoRegistLimit
        self.dropConvertRatio = dropConvertRatio
        self.syncCycle = syncCycle
    }
    
    init(){
        self.userId = ""
        self.projectRegistLimit = 0
        self.todoRegistLimit = 0
        self.dropConvertRatio = 0
        self.syncCycle = 0
    }
}
