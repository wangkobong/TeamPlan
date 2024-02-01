//
//  ChallengeLog.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/10/20.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation

let challengeLogId = 1
//============================
// MARK: Entity
//============================
struct ChallengeLog{

    //--------------------
    // content
    //--------------------
    let log_id: Int
    let log_user_id: String
    var log_complete: [Int : Date]
    var log_upload_at: Date
    
    //--------------------
    // constructor
    //--------------------
    // Default
    init(){
        self.log_id = 0
        self.log_user_id = "unknown"
        self.log_complete = [:]
        self.log_upload_at = Date()
    }
    
    // Signup
    init(logId: Int, userId: String, challengeId: Int, completeDate: Date){
        self.log_id = logId
        self.log_user_id = userId
        self.log_complete = [challengeId : completeDate]
        self.log_upload_at = completeDate
    }
    
    // Coredatat
    init?(from entity: ChallengeLogEntity, log: [Int : Date]){
        guard let log_user_id = entity.log_user_id,
              let log_upload_at = entity.log_upload_at
        else {
            return nil
        }
        self.log_id = Int(entity.log_id)
        self.log_user_id = log_user_id
        self.log_complete = log
        self.log_upload_at = log_upload_at
    }
    
    // Firestore
    init?(from data: [String : Any]) {
        guard let log_id = data["log_id"] as? Int,
              let log_user_id = data["log_user_id"] as? String,
              let log_complete_string = data["log_complete"] as? [String : String],
              let log_upload_at_string = data["log_upload_at"] as? String,
              let log_upload_at = DateFormatter.standardFormatter.date(from: log_upload_at_string)
        else {
            return nil
        }
        let log_complete = log_complete_string
            .compactMapKeys{ Int($0) }
            .compactMapValues{ DateFormatter.standardFormatter.date(from: $0) }

        // Assigning values
        self.log_id = log_id
        self.log_user_id = log_user_id
        self.log_complete = log_complete
        self.log_upload_at = log_upload_at
    }
    
    //--------------------
    // function
    //--------------------
    mutating func updateUploadAt(with newDate: Date){
        self.log_upload_at = newDate
    }
    
    // Dictionary Converter
    func toDictionary() -> [String: Any] {
        let log_complete_string = log_complete
            .mapKeys{ String($0) }
            .mapValues{ DateFormatter.standardFormatter.string(from: $0) }

        return [
            "log_id": log_id,
            "log_user_id": log_user_id,
            "log_complete": log_complete_string,
            "log_upload_at": DateFormatter.standardFormatter.string(from: log_upload_at)
        ]
    }
}

//============================
// MARK: DTO
//============================
struct ChallengeLogUpdateDTO{
    
    //--------------------
    // content
    //--------------------
    let userId: String
    let logId: Int
    
    var challengeId: Int?
    var updatedAt: Date?
    var uploadAt: Date?
    
    //--------------------
    // constructor
    //--------------------
    init(userId: String, logId: Int,
         challengeId: Int? = nil,
         updatedAt: Date? = nil,
         uploadAt: Date? = nil
    ) {
        self.userId = userId
        self.logId = logId
        self.challengeId = challengeId
        self.updatedAt = updatedAt
        self.uploadAt = uploadAt
    }
}
