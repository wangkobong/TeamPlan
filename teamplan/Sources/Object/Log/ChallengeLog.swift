//
//  ChallengeLog.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/10/20.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation

struct ChallengeLog{
    // id
    let log_user_id: String
    
    //content
    var log_complete: [Int : Date]
    let log_update_at: Date
    
    // constructor
    init(identifier: String, signupDate: Date){
        self.log_user_id = identifier
        self.log_complete = [:]
        self.log_update_at = signupDate
    }
    
    // func
    func toDictionary() -> [String : Any] {
        return [
            "log_user_id" : self.log_user_id,
            "log_complete" : self.log_complete,
            "log_update_at" : self.log_update_at
        ]
    }
}

