//
//  AccessLog.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/10/20.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation

struct AccessLog{
    
    //============================
    // MARK: Data
    //============================
    // id
    let log_user_id: String
    
    // content
    var log_access: [Date]
    
    //============================
    // MARK: Constuctor
    //============================
    // : Signup (Service)
    init(identifier: String, signupDate: Date){
        self.log_user_id = identifier
        self.log_access = [signupDate]
    }
    
    // : Get (Coredata)
    init?(logEntity: AccessLogEntity) {
        guard let log_user_id = logEntity.log_user_id,
              let log_access = logEntity.log_access as? [Date]
        else {
            return nil
        }
        // Assigning values
        self.log_user_id = log_user_id
        self.log_access = log_access
    }
    
    // : Get (Firestore)
    init?(logData: [String : Any]) {
        guard let log_user_id = logData["log_user_id"] as? String,
              let log_access_string = logData["log_access"] as? [String]
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
