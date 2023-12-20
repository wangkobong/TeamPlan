//
//  StatisticsDTO.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/10/25.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation

//================================
// MARK: - LoginLoading
//================================
struct StatLoginDTO {

    //--------------------
    // content
    //--------------------
    let type: DTOType = .login
    let stat_user_id: String
    
    var stat_term: Int
    
    //--------------------
    // constructor
    //--------------------
    // Default
    init(){
        self.stat_user_id = ""
        self.stat_term = 0
    }
    // Coredata
    init(with userId: String, entity: StatisticsEntity){
        self.stat_user_id = userId
        self.stat_term = Int(entity.stat_term)
    }
    // Firestore
    init(with object: StatisticsObject){
        self.stat_user_id = object.stat_user_id
        self.stat_term = object.stat_term
    }
    
    //--------------------
    // function
    //--------------------
    mutating func updateServiceTerm(with newTerm: Int){
        self.stat_term = newTerm
    }
}

//================================
// MARK: - Challenge
//================================
struct StatChallengeDTO {
    
    //--------------------
    // content
    //--------------------
    let type: DTOType = .challenge
    let stat_user_id: String
    
    var stat_drop: Int
    var stat_chlg_step: [Int : Int]
    var stat_mychlg: [Int]
    
    //--------------------
    // constructor
    //--------------------
    // Default
    init(){
        self.stat_user_id = ""
        self.stat_drop = 0
        self.stat_chlg_step = [ : ]
        self.stat_mychlg = []
    }
    // Coredata Entity
    init(with userId: String, entity: StatisticsEntity, chlgStep: [Int : Int], mychlg: [Int]){
        self.stat_user_id = userId
        self.stat_drop = Int(entity.stat_drop)
        self.stat_chlg_step = chlgStep
        self.stat_mychlg = mychlg
    }
    
    //--------------------
    // function
    //--------------------
    mutating func updateDrop(with newDrop: Int){
        self.stat_drop = newDrop
    }
    mutating func updateChallengeStep(with newChlgStep: [Int : Int]){
        self.stat_chlg_step = newChlgStep
    }
    mutating func updateMyChallenge(with newMychlg: [Int]){
        self.stat_mychlg = newMychlg
    }
}

//================================
// MARK: - StatCenter
//================================
struct StatCenterDTO {
    
    //--------------------
    // content
    //--------------------
    let type: DTOType = .center
    let stat_user_id: String
    
    let stat_term: Int
    let stat_drop: Int
    
    let stat_proj_reg: Int
    let stat_proj_fin: Int
    let stat_proj_alert: Int
    let stat_proj_ext: Int
    let stat_todo_reg: Int

    let stat_chlg_step: [Int : Int]
    let stat_mychlg: [Int]
    //--------------------
    // constructor
    //--------------------
    // Default
    init(){
        self.stat_user_id = ""
        self.stat_term = 0
        self.stat_drop = 0
        self.stat_proj_reg = 0
        self.stat_proj_fin = 0
        self.stat_proj_alert = 0
        self.stat_proj_ext = 0
        self.stat_todo_reg = 0
        self.stat_chlg_step = [:]
        self.stat_mychlg = []
    }
    // Coredata Entity
    init(with userId: String, entity: StatisticsEntity, chlgStep: [Int : Int], mychlg: [Int]){
        self.stat_user_id = userId
        self.stat_term = Int(entity.stat_term)
        self.stat_drop = Int(entity.stat_drop)
        self.stat_proj_reg = Int(entity.stat_proj_reg)
        self.stat_proj_fin = Int(entity.stat_proj_fin)
        self.stat_proj_alert = Int(entity.stat_proj_alert)
        self.stat_proj_ext = Int(entity.stat_proj_ext)
        self.stat_todo_reg = Int(entity.stat_todo_reg)
        self.stat_chlg_step = chlgStep
        self.stat_mychlg = mychlg
    }
}

//================================
// MARK: - Project
//================================
struct StatProjectDTO {
    
    //--------------------
    // content
    //--------------------
    let type: DTOType = .project
    let stat_user_id: String
    
    var stat_drop: Int
    var stat_proj_reg: Int
    var stat_proj_fin: Int
    var stat_proj_alert: Int
    var stat_proj_ext: Int
    var stat_todo_reg: Int
    
    //--------------------
    // constructor
    //--------------------
    init(with userId: String, entity: StatisticsEntity){
        self.stat_user_id = userId
        self.stat_drop = Int(entity.stat_drop)
        self.stat_proj_reg = Int(entity.stat_proj_reg)
        self.stat_proj_fin = Int(entity.stat_proj_fin)
        self.stat_proj_alert = Int(entity.stat_proj_alert)
        self.stat_proj_ext = Int(entity.stat_proj_ext)
        self.stat_todo_reg = Int(entity.stat_todo_reg)
    }
    
    //--------------------
    // function
    //--------------------
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

//================================
// MARK: - Update
//================================
struct StatUpdateDTO {
    
    //--------------------
    // content
    //--------------------
    let stat_user_id: String
    var stat_drop: Int?
    var stat_term: Int?
    
    // Challenge specific fields
    var stat_chlg_step: [Int : Int]?
    var stat_mychlg: [Int]?

    // Project specific fields
    var stat_proj_reg: Int?
    var stat_proj_fin: Int?
    var stat_proj_alert: Int?
    var stat_proj_ext: Int?
    var stat_todo_reg: Int?
    
    //--------------------
    // constructor
    //--------------------
    // Login
    init(loginDTO: StatLoginDTO) {
        self.stat_user_id = loginDTO.stat_user_id
        self.stat_term = loginDTO.stat_term
    }
    // Challenge
    init(challengeDTO: StatChallengeDTO) {
        self.stat_user_id = challengeDTO.stat_user_id
        self.stat_drop = challengeDTO.stat_drop
        self.stat_chlg_step = challengeDTO.stat_chlg_step
        self.stat_mychlg = challengeDTO.stat_mychlg
    }
    // Project
    init(projectDTO: StatProjectDTO) {
        self.stat_user_id = projectDTO.stat_user_id
        self.stat_drop = projectDTO.stat_drop
        self.stat_proj_reg = projectDTO.stat_proj_reg
        self.stat_proj_fin = projectDTO.stat_proj_fin
        self.stat_proj_alert = projectDTO.stat_proj_alert
        self.stat_proj_ext = projectDTO.stat_proj_ext
        self.stat_todo_reg = projectDTO.stat_todo_reg
    }
    
    //--------------------
    // function
    //--------------------
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [:]
        dict["stat_user_id"] = stat_user_id

        // Optional fields are added only if they are non-nil.
        if let statDrop = stat_drop {
            dict["stat_drop"] = statDrop
        }
        if let statTerm = stat_term {
            dict["stat_term"] = statTerm
        }
        if let statChlgStep = stat_chlg_step {
            dict["stat_chlg_step"] = statChlgStep
        }
        if let statMychlg = stat_mychlg {
            dict["stat_mychlg"] = statMychlg
        }
        if let statProjReg = stat_proj_reg {
            dict["stat_proj_reg"] = statProjReg
        }
        if let statProjFin = stat_proj_fin {
            dict["stat_proj_fin"] = statProjFin
        }
        if let statProjAlert = stat_proj_alert {
            dict["stat_proj_alert"] = statProjAlert
        }
        if let statProjExt = stat_proj_ext {
            dict["stat_proj_ext"] = statProjExt
        }
        if let statTodoReg = stat_todo_reg {
            dict["stat_todo_reg"] = statTodoReg
        }
        return dict
    }
}

//================================
// MARK: - Type
//================================
enum DTOType {
    case login
    case challenge
    case project
    case center
}


//================================
// MARK: - Legacy
//================================
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
    var stat_chlg_step: [Int : Int]
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
        self.stat_chlg_step = [:]
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
