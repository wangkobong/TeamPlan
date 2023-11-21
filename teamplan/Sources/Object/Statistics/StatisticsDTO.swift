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
    var stat_mychlg: [Int]
    
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
    init() {
        self.stat_user_id = "unknown"
        self.stat_term = 0
        self.stat_drop = 0
        self.stat_proj_reg = 0
        self.stat_proj_fin = 0
        self.stat_proj_alert = 0
        self.stat_proj_ext = 0
        self.stat_todo_reg = 0
        self.stat_chlg_step = [[:]]
        self.stat_mychlg = []
        self.stat_upload_at = Date()
    }

    // ===== Update
    mutating func updateServiceTerm(to term: Int){
        self.stat_term = term
    }
    
    mutating func updateWaterDrop(to drop: Int){
        self.stat_drop = drop
    }
    
    mutating func updateProjectRegist(to projectRegist: Int){
        self.stat_proj_reg = projectRegist
    }
    
    mutating func updateProjectFinish(to projectFinish: Int){
        self.stat_proj_fin = projectFinish
    }
    
    mutating func updateProjectAlert(to projectAlert: Int){
        self.stat_proj_alert = projectAlert
    }
    
    mutating func updateProjectExtend(to projectExtend: Int){
        self.stat_proj_ext = projectExtend
    }
    
    mutating func updateTodoRegist(to todoRegist: Int){
        self.stat_todo_reg = todoRegist
    }
}
