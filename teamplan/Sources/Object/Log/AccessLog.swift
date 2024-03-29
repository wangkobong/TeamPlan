//
//  AccessLog.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/10/20.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation

struct AccessLog{
    
    let userId: String
    let accessRecord: Date
    
    init(userId: String, accessDate: Date){
        self.userId = userId
        self.accessRecord = accessDate
    }
}


