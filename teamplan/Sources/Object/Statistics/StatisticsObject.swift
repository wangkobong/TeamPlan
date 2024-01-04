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
    let stat_upload_at: Date
    
    //--------------------
    // constructor
    //--------------------
    // SignupService
    init(identifier: String, signupDate: Date){
        self.stat_user_id = identifier
        self.stat_term = 0
        self.stat_drop = 0
        self.stat_proj_reg = 0
        self.stat_proj_fin = 0
        self.stat_proj_alert = 0
        self.stat_proj_ext = 0
        self.stat_todo_reg = 0
        self.stat_todo_limit = 10
        self.stat_chlg_step = [
            ChallengeType.serviceTerm.rawValue : 1,
            ChallengeType.totalTodo.rawValue : 1,
            ChallengeType.projectAlert.rawValue : 1,
            ChallengeType.projectFinish.rawValue : 1,
            ChallengeType.waterDrop.rawValue : 1
        ]
        self.stat_mychlg = []
        self.stat_upload_at = signupDate
    }
    
    //--------------------
    // constructor
    //--------------------
    // Coredata
    init?(entity: StatisticsEntity, chlgStep: [Int : Int], mychlg: [Int]){
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
        self.stat_chlg_step = chlgStep
        self.stat_mychlg = mychlg
        self.stat_upload_at = stat_upload_at
    }
    // Firestore
    init?(statData: [String : Any]){
        // Pharsing Normal Data
        guard let stat_user_id = statData["stat_user_id"] as? String,
              let stat_term = statData["stat_term"] as? Int,
              let stat_drop = statData["stat_drop"] as? Int,
              let stat_proj_reg = statData["stat_proj_reg"] as? Int,
              let stat_proj_fin = statData["stat_proj_fin"] as? Int,
              let stat_proj_alert = statData["stat_proj_alert"] as? Int,
              let stat_proj_ext = statData["stat_proj_ext"] as? Int,
              let stat_todo_reg = statData["stat_todo_reg"] as? Int,
              let stat_todo_limit = statData["stat_todo_limit"] as? Int,
              let stat_chlg_step_firestore = statData["stat_chlg_step"] as? [String : Int],
              let stat_upload_at_string = statData["stat_upload_at"] as? String,
              let stat_upload_at = DateFormatter.standardFormatter.date(from: stat_upload_at_string)
        else {
            return nil
        }
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
        self.stat_mychlg = statData["stat_mychlg"] as? [Int] ?? []
        self.stat_chlg_step = stat_chlg_step_firestore.compactMapKeys { Int($0) }
    }
    
    //--------------------
    // function
    //--------------------
    func toDictionary() -> [String : Any] {
        let stat_chlg_step_firestore = self.stat_chlg_step.mapKeys{ String($0) }
        
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
            "stat_chlg_step": stat_chlg_step_firestore,
            "stat_upload_at": DateFormatter.standardFormatter.string(from: self.stat_upload_at)
        ]
    }
}
