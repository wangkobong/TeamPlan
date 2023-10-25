//
//  StatisticsDTO.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/10/25.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation

struct StatisticsDTO{
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
    init(statObject: StatisticsObject) {
        self.stat_user_id = statObject.stat_user_id
        self.stat_term = statObject.stat_term
        self.stat_drop = statObject.stat_drop
        self.stat_proj_reg = statObject.stat_proj_reg
        self.stat_proj_fin = statObject.stat_proj_fin
        self.stat_proj_alert = statObject.stat_proj_alert
        self.stat_proj_ext = statObject.stat_proj_ext
        self.stat_todo_reg = statObject.stat_todo_reg
        self.stat_chlg_step = statObject.stat_chlg_step
        self.stat_mychlg = statObject.stat_mychlg
        self.stat_upload_at = statObject.stat_upload_at
    }
    
    // Func
    mutating func updateServiceTerm(updatedTerm: Int){
        self.stat_term = updatedTerm
    }
}
