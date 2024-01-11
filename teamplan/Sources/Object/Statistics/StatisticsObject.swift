//
//  StatisticsObject.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/10/10.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation

struct StatisticsObject{
    
    //--------------------
    // content
    //--------------------
    let stat_user_id: String
    let stat_term: Int
    let stat_drop: Int
    let stat_proj_reg: Int
    let stat_proj_fin: Int
    let stat_proj_alert: Int
    let stat_proj_ext: Int
    let stat_todo_reg: Int
    let stat_todo_limit: Int
    let stat_chlg_step: [Int : Int]
    let stat_mychlg: [Int]
    let stat_log_head: [Int : Int]
    let stat_upload_at: Date
    
    //--------------------
    // constructor
    //--------------------
    // Signup
    init(userId: String, setDate: Date){
        self.stat_user_id = userId
        self.stat_term = 0
        self.stat_drop = 0
        self.stat_proj_reg = 0
        self.stat_proj_fin = 0
        self.stat_proj_alert = 0
        self.stat_proj_ext = 0
        self.stat_todo_reg = 0
        self.stat_todo_limit = 0
        self.stat_chlg_step = [
            ChallengeType.serviceTerm.rawValue : 1,
            ChallengeType.totalTodo.rawValue : 1,
            ChallengeType.projectAlert.rawValue : 1,
            ChallengeType.projectFinish.rawValue : 1,
            ChallengeType.waterDrop.rawValue : 1
        ]
        self.stat_mychlg = []
        self.stat_log_head = [
            LogType.access.rawValue : 1,
            LogType.challenge.rawValue : 1
        ]
        self.stat_upload_at = setDate
    }
    
    // Coredata
    init?(entity: StatisticsEntity, challengeStep: [Int : Int], myChallenge: [Int], logHead: [Int: Int]){
        guard let stat_user_id = entity.stat_user_id,
              let stat_upload_at = entity.stat_upload_at
        else {
            return nil
        }
        // Assigning values
        self.stat_user_id = stat_user_id
        self.stat_term = Int(entity.stat_term)
        self.stat_drop = Int(entity.stat_drop)
        self.stat_proj_reg = Int(entity.stat_proj_reg)
        self.stat_proj_fin = Int(entity.stat_proj_fin)
        self.stat_proj_alert = Int(entity.stat_proj_alert)
        self.stat_proj_ext = Int(entity.stat_proj_ext)
        self.stat_todo_reg = Int(entity.stat_todo_reg)
        self.stat_todo_limit = Int(entity.stat_todo_limit)
        self.stat_chlg_step = challengeStep
        self.stat_mychlg = myChallenge
        self.stat_log_head = logHead
        self.stat_upload_at = stat_upload_at
    }
    // Firestore
    init?(with data: [String : Any]){
        // Pharsing Normal Data
        guard let stat_user_id = data["stat_user_id"] as? String,
              let stat_term = data["stat_term"] as? Int,
              let stat_drop = data["stat_drop"] as? Int,
              let stat_proj_reg = data["stat_proj_reg"] as? Int,
              let stat_proj_fin = data["stat_proj_fin"] as? Int,
              let stat_proj_alert = data["stat_proj_alert"] as? Int,
              let stat_proj_ext = data["stat_proj_ext"] as? Int,
              let stat_todo_reg = data["stat_todo_reg"] as? Int,
              let stat_todo_limit = data["stat_todo_limit"] as? Int,
              let stat_chlg_step_string = data["stat_chlg_step"] as? [String : String],
              let stat_log_head_string = data["stat_log_head"] as? [String : String],
              let stat_upload_at_string = data["stat_upload_at"] as? String,
              let stat_upload_at = DateFormatter.standardFormatter.date(from: stat_upload_at_string)
        else {
            return nil
        }
        let stat_chlg_step = stat_chlg_step_string
            .compactMapKeys { Int($0) }
            .compactMapValues { Int($0) }
        let stat_log_head = stat_log_head_string
            .compactMapKeys { Int($0) }
            .compactMapValues { Int($0) }
        
        // Assigning values
        self.stat_user_id = stat_user_id
        self.stat_term = stat_term
        self.stat_drop = stat_drop
        self.stat_proj_reg = stat_proj_reg
        self.stat_proj_fin = stat_proj_fin
        self.stat_proj_alert = stat_proj_alert
        self.stat_proj_ext = stat_proj_ext
        self.stat_todo_reg = stat_todo_reg
        self.stat_todo_limit = stat_todo_limit
        self.stat_upload_at = stat_upload_at
        self.stat_mychlg = data["stat_mychlg"] as? [Int] ?? []
        self.stat_log_head = stat_log_head
        self.stat_chlg_step = stat_chlg_step
    }
    
    //--------------------
    // function
    //--------------------
    func toDictionary() -> [String : Any] {
        let challengeStepString = stat_chlg_step
            .mapKeys { String($0) }
            .mapValues { String($0) }
        let logHeadString = stat_log_head
            .mapKeys { String($0) }
            .mapValues { String($0) }
        
        return [
            "stat_user_id": self.stat_user_id,
            "stat_term": self.stat_term,
            "stat_drop": self.stat_drop,
            "stat_proj_reg": self.stat_proj_reg,
            "stat_proj_fin": self.stat_proj_fin,
            "stat_proj_alert": self.stat_proj_alert,
            "stat_proj_ext": self.stat_proj_ext,
            "stat_todo_reg": self.stat_todo_reg,
            "stat_todo_limit" : self.stat_todo_limit,
            "stat_mychlg": self.stat_mychlg,
            "stat_chlg_step": challengeStepString,
            "stat_log_head": logHeadString,
            "stat_upload_at": DateFormatter.standardFormatter.string(from: self.stat_upload_at)
        ]
    }
}

//================================
// MARK: - Enum
//================================
enum LogType: Int{
    case access = 1
    case challenge = 2
}
