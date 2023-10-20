//
//  StatisticsObject.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/10/10.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation

struct StatisticsObject{
    // id
    let stat_user_id: String
    
    //content: Etc
    var stat_term: Int
    var stat_drop: Int
    
    //content: Project & Todo
    var stat_proj_reg: Int
    var stat_proj_fin: Int
    var stat_proj_alert: Int
    var stat_proj_ext: Int
    var stat_todo_reg: Int
    
    //content: Challenge
    var stat_chlg_step: [[Int : Int]]
    var stat_mychlg: [Int : Int]
    
    // maintenance
    var stat_upload_at: Date
    
    // Constructor
    // : Signup
    init(identifier: String, signupDate: Date){
        self.stat_user_id = identifier
        self.stat_term = 0
        self.stat_drop = 0
        self.stat_proj_reg = 0
        self.stat_proj_fin = 0
        self.stat_proj_alert = 0
        self.stat_proj_ext = 0
        self.stat_todo_reg = 0
        self.stat_chlg_step = [
            [ChallengeType.serviceTerm.rawValue : 1],
            [ChallengeType.totalTodo.rawValue : 1],
            [ChallengeType.projectRegist.rawValue : 1],
            [ChallengeType.projectFinish.rawValue : 1],
            [ChallengeType.waterDrop.rawValue : 1]
        ]
        self.stat_mychlg = [:]
        self.stat_upload_at = signupDate
    }
    
    // : CoreData
    init(statEntity: StatisticsEntity) {
        self.stat_user_id = statEntity.stat_user_id ?? "Unknown"
        self.stat_term = Int(statEntity.stat_term)
        self.stat_drop = Int(statEntity.stat_drop)
        self.stat_proj_reg = Int(statEntity.stat_proj_reg)
        self.stat_proj_fin = Int(statEntity.stat_proj_fin)
        self.stat_proj_alert = Int(statEntity.stat_proj_alert)
        self.stat_proj_ext = Int(statEntity.stat_proj_ext)
        self.stat_todo_reg = Int(statEntity.stat_todo_reg)
        self.stat_chlg_step = statEntity.stat_chlg_step as! [[Int : Int]]
        self.stat_mychlg = statEntity.stat_mychlg as! [Int : Int]
        self.stat_upload_at = statEntity.stat_upload_at ?? Date()
    }
    
    //============================
    // MARK: Func
    //============================
    func toDictionary() -> [String : Any] {
        return [
            "stat_user_id": self.stat_user_id,
            "stat_term": self.stat_term,
            "stat_drop": self.stat_drop,
            "stat_proj_reg": self.stat_proj_reg,
            "stat_proj_fin": self.stat_proj_fin,
            "stat_proj_alert": self.stat_proj_alert,
            "stat_proj_ext": self.stat_proj_ext,
            "stat_todo_reg": self.stat_todo_reg,
            "stat_chlg_step": self.stat_chlg_step,
            "stat_mychlg": self.stat_mychlg,
            "stat_upload_at": self.stat_upload_at
        ]
    }
}
