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
    
    //--------------------
    // content
    //--------------------
    let log_user_id: String
    var log_access: [Date]
    
    //--------------------
    // constructor
    //--------------------
    // Signup
    init(identifier: String, signupDate: Date){
        self.log_user_id = identifier
        self.log_access = [signupDate]
    }
    
    // Coredata
    init(with userId: String, and log: [Date]) {
        self.log_user_id = userId
        self.log_access = log
    }
    
    // Firestore
    init?(logData: [String : Any]) {
        guard let log_user_id = logData["log_user_id"] as? String,
              let log_access_string = logData["log_access"] as? [String]
        else {
            return nil
        }
        // Data Convert
        let logDates = log_access_string.compactMap { DateFormatter.standardFormatter.date(from: $0) }
        guard logDates.count == log_access_string.count else {
            return nil
        }
        // Assigning values
        self.log_user_id = log_user_id
        self.log_access = logDates
    }
    
    // Default
    init(){
        self.log_user_id = "unknown"
        self.log_access = []
    }
    
    //--------------------
    // Function
    //--------------------
    func toDictionary() -> [String : Any] {
        let logStrings = log_access.map { DateFormatter.standardFormatter.string(from: $0) }
        
        return [
            "log_user_id" : self.log_user_id,
            "log_access" : logStrings
        ]
    }
}
