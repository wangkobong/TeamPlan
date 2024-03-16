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
    
    init(userId: String, projectRegistLimit: Int, todoRegistLimit: Int, dropConvertRatio: Float, syncCycle: Int) {
        self.userId = userId
        self.projectRegistLimit = projectRegistLimit
        self.todoRegistLimit = todoRegistLimit
        self.dropConvertRatio = dropConvertRatio
        self.syncCycle = syncCycle
    }
    
    init?(entity: CoreValueEntity) {
        guard let userId = entity.user_id else { return nil
        }
        self.userId = userId
        self.projectRegistLimit = Int(entity.project_regist_limit)
        self.todoRegistLimit = Int(entity.todo_regist_limit)
        self.dropConvertRatio = entity.drop_convert_ratio
        self.syncCycle = Int(entity.sync_cycle)
    }
}
