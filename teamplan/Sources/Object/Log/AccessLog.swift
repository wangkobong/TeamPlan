//
//  AccessLog.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/10/20.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation
import FirebaseFirestore

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
    init?(acclogData: [String : Any]) {
        guard let log_user_id = acclogData["log_user_id"] as? String,
              let log_access_string = acclogData["log_access"] as? [String]
        else {
            return nil
        }
        // Date Converter
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        
        let logDates = log_access_string.compactMap { formatter.date(from: $0) }
        guard logDates.count == log_access_string.count else {
            return nil
        }
        
        // Assigning values
        self.log_user_id = log_user_id
        self.log_access = logDates
    }
    
    //============================
    // MARK: Func
    //============================
    func toDictionary() -> [String : Any] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        
        let logStrings = self.log_access.map { formatter.string(from: $0) }
        
        return [
            "log_user_id" : self.log_user_id,
            "log_access" : logStrings
        ]
    }
}
