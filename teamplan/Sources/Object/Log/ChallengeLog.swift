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
    // : SignupService
    init(identifier: String, signupDate: Date){
        self.log_user_id = identifier
        self.log_complete = [:]
        self.log_update_at = signupDate
    }
    
    // : Get (Coredatat)
    init?(logEntity: ChallengeLogEntity){
        guard let log_user_id = logEntity.log_user_id,
              let log_complete = logEntity.log_complete as? [Int : Date],
              let log_update_at = logEntity.log_update_at
        else {
            return nil
        }
        self.log_user_id = log_user_id
        self.log_complete = log_complete
        self.log_update_at = log_update_at
    }
    
    // : Get (Firestore)
    init?(challengeData: [String : Any]) {
        guard let log_user_id = challengeData["log_user_id"] as? String,
              let log_complete_string = challengeData["log_complete"] as? [Int : String],
              let log_update_at_string = challengeData["log_update_at"] as? String
        else {
            return nil
        }
        // Date Converter
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        
        var log_complete: [Int: Date] = [:]
        for (key, dateString) in log_complete_string {
            log_complete[key] = formatter.date(from: dateString)
        }
        guard let log_update_at = formatter.date(from: log_update_at_string) else {
                return nil
        }
        
        // Assigning values
        self.log_user_id = log_user_id
        self.log_complete = log_complete
        self.log_update_at = log_update_at
    }
    
    //============================
    // MARK: Func
    //============================
    func toDictionary() -> [String : Any] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        
        let logCompleteStrings = self.log_complete.mapValues { formatter.string(from: $0) }
        let logUpdateStrings = formatter.string(from: self.log_update_at)
        
        return [
            "log_user_id" : self.log_user_id,
            "log_complete" : logCompleteStrings,
            "log_update_at" : logUpdateStrings
        ]
    }
}

