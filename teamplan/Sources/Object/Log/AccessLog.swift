//
//  AccessLog.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/10/20.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation

struct AccessLog{
    // id
    let log_user_id: String
    
    // content
    var log_access: [Date]
    
    // constructor
    init(identifier: String, signupDate: Date){
        self.log_user_id = identifier
        self.log_access = [signupDate]
    }
    
    // func
    func toDictionary() -> [String : Any] {
        return [
            "log_user_id" : self.log_user_id,
            "log_access" : self.log_access
        ]
    }
}
