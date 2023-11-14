//
//  ChallengeLog.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/10/20.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation

//============================
// MARK: Entity
//============================
struct ChallengeLog{
    // id
    let log_user_id: String
    
    //content
    var log_complete: [[Int : Date]]
    var log_update_at: Date
    
    //============================
    // MARK: Constructor
    //============================
    // : SignupService
    init(identifier: String, signupDate: Date){
        self.log_user_id = identifier
        self.log_complete = [[:]]
        self.log_update_at = signupDate
    }
    
    // : Get (Coredatat)
    init?(from entity: ChallengeLogEntity, log: [[Int : Date]]){
        guard let log_user_id = entity.log_user_id,
              let log_update_at = entity.log_update_at
        else {
            return nil
        }
        self.log_user_id = log_user_id
        self.log_complete = log
        self.log_update_at = log_update_at
    }
    
    // : Get (Firestore)
    init?(challengeData: [String : Any]) {
        guard let log_user_id = challengeData["log_user_id"] as? String,
              let log_complete_string = challengeData["log_complete"] as? [[Int : String]],
              let log_update_at_string = challengeData["log_update_at"] as? String
        else {
            return nil
        }
        // Date Converter
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        
        // Ready Array
        var log_complete: [[Int: Date]] = []
        for dict in log_complete_string {
            
            // Ready Dictionary
            var convertedDict: [Int : Date] = [:]
            for (key, dateString) in dict {
                if let date = formatter.date(from: dateString) {
                    convertedDict[key] = date
                }
            }
            if !convertedDict.isEmpty {
                log_complete.append(convertedDict)
            }
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
        
        let logCompleteStrings = self.log_complete.map { dict in
            dict.mapValues { formatter.string(from: $0) }}
        let logUpdateStrings = formatter.string(from: self.log_update_at)
        
        return [
            "log_user_id" : self.log_user_id,
            "log_complete" : logCompleteStrings,
            "log_update_at" : logUpdateStrings
        ]
    }
    
    mutating func recordLog(num challengeId: Int, at addedDate: Date){
        self.log_complete.append([challengeId : addedDate])
    }
    
    mutating func updateDate(to updatedDate: Date){
        self.log_update_at = updatedDate
    }
    
    mutating func setLogComplete(from log: [[Int : Date]]){
        self.log_complete = log
    }
}

