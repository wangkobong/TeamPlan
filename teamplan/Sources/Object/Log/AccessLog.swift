//
//  AccessLog.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/10/20.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation

//============================
// MARK: Entity
//============================
struct AccessLog{
    // id
    let log_user_id: String
    
    // content
    var log_access: [Date]
    
    // Constructor
    // : Signup
    init(identifier: String, signupDate: Date){
        self.log_user_id = identifier
        self.log_access = [signupDate]
    }
    
    // : Get (Coredata)
    init(acclogEntity: AccessLogEntity) {
        self.log_user_id = acclogEntity.log_user_id!
        self.log_access = acclogEntity.log_access as! [Date]
    }
    
    // : Get (Firestore)
    init?(acclogData: [String : Any]){
        guard let log_user_id = acclogData["log_user_id"] as? String,
              let log_access = acclogData["log_access"] as? [Date]
        else {
            return nil
        }
        // Assigning values
        self.log_user_id = log_user_id
        self.log_access = log_access
    }
    
    //============================
    // MARK: Func
    //============================
    func toDictionary() -> [String : Any] {
        return [
            "log_user_id" : self.log_user_id,
            "log_access" : self.log_access
        ]
    }
}
