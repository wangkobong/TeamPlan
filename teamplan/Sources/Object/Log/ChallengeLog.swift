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

    //--------------------
    // content
    //--------------------
    let log_user_id: String
    var log_complete: [Int : Date]
    var log_update_at: Date
    
    //--------------------
    // constructor
    //--------------------
    // SignupService
    init(identifier: String, signupDate: Date){
        self.log_user_id = identifier
        self.log_complete = [100 : signupDate]
        self.log_update_at = signupDate
    }
    
    // Coredatat
    init?(from entity: ChallengeLogEntity, log: [Int : Date]){
        guard let log_user_id = entity.log_user_id,
              let log_update_at = entity.log_update_at
        else {
            return nil
        }
        self.log_user_id = log_user_id
        self.log_complete = log
        self.log_update_at = log_update_at
    }
    
    // Firestore
    init?(challengeData: [String : Any]) {
        guard let log_user_id = challengeData["log_user_id"] as? String,
              let log_complete_firestore = challengeData["log_complete"] as? [String : String],
              let log_update_at_string = challengeData["log_update_at"] as? String,
              let log_update_at = DateFormatter.standardFormatter.date(from: log_update_at_string)
        else {
            return nil
        }
        let log_complete = log_complete_firestore
            .compactMapKeys{ Int($0) }
            .compactMapValues{ DateFormatter.standardFormatter.date(from: $0) }

        // Assigning values
        self.log_user_id = log_user_id
        self.log_complete = log_complete
        self.log_update_at = log_update_at
    }
    
    //--------------------
    // function
    //--------------------
    // Dictionary Converter
    func toDictionary() -> [String: Any] {
        let log_complete_string = log_complete
            .mapKeys{ String($0) }
            .mapValues{ DateFormatter.standardFormatter.string(from: $0) }

        return [
            "log_user_id": log_user_id,
            "log_complete": log_complete_string,
            "log_update_at": DateFormatter.standardFormatter.string(from: log_update_at)
        ]
    }
    // mutating
    mutating func recordLog(num challengeId: Int, at addedDate: Date){
        self.log_complete[challengeId] = addedDate
    }
    mutating func updateDate(to updatedDate: Date){
        self.log_update_at = updatedDate
    }
    mutating func setLogComplete(from log: [Int : Date]){
        self.log_complete = log
    }
}

