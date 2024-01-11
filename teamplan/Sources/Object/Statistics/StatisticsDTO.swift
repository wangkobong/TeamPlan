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
    let userId: String
    
    var term: Int
    var todoLimit: Int
    
    //--------------------
    // constructor
    //--------------------
    // Default
    init(){
        self.userId = ""
        self.term = 0
        self.todoLimit = 0
    }
    // CoredataService
    init(with userId: String, entity: StatisticsEntity){
        self.userId = userId
        self.term = Int(entity.stat_term)
        self.todoLimit = Int(entity.stat_todo_limit)
    }
    
    //--------------------
    // function
    //--------------------
    mutating func updateServiceTerm(with newTerm: Int){
        self.term = newTerm
    }
    mutating func updateTodoLimit(with newVal: Int){
        self.todoLimit = newVal
    }
}

//================================
// MARK: - Home
//================================
struct StatHomeDTO{
    
    //--------------------
    // content
    //--------------------
    let type: DTOType = .home
    let userId: String
    let waterDrop: Int
    
    //--------------------
    // constructor
    //--------------------
    // Default
    init() {
        self.userId = ""
        self.waterDrop = 0
    }
    // Coredata
    init(with userId: String, entity: StatisticsEntity){
        self.userId = userId
        self.waterDrop = Int(entity.stat_drop)
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
    let userId: String
    
    var drop: Int
    var challengeStep: [Int : Int]
    var myChallenge: [Int]
    
    //--------------------
    // constructor
    //--------------------
    // Default
    init(){
        self.userId = ""
        self.drop = 0
        self.challengeStep = [ : ]
        self.myChallenge = []
    }
    // CoredataService
    init(with userId: String, entity: StatisticsEntity, chlgStep: [Int : Int], mychlg: [Int]){
        self.userId = userId
        self.drop = Int(entity.stat_drop)
        self.challengeStep = chlgStep
        self.myChallenge = mychlg
    }
    
    //--------------------
    // function
    //--------------------
    mutating func updateDrop(with newDrop: Int){
        self.drop = newDrop
    }
    mutating func updateChallengeStep(with newChlgStep: [Int : Int]){
        self.challengeStep = newChlgStep
    }
    mutating func updateMyChallenge(with newMychlg: [Int]){
        self.myChallenge = newMychlg
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
    // CoredataService
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
/// PageService <=> StorageService DTO
struct StatProjectDTO {
    
    //--------------------
    // content
    //--------------------
    let type: DTOType = .project
    let userId: String
    
    var waterDrop: Int
    var projectRegisted: Int
    var projectFinished: Int
    var projectAlerted: Int
    var projectExtended: Int
    var todoRegisted: Int
    
    //--------------------
    // constructor
    //--------------------
    // Default
    init(){
        self.userId = ""
        self.waterDrop = 0
        self.projectRegisted = 0
        self.projectFinished = 0
        self.projectAlerted = 0
        self.projectExtended = 0
        self.todoRegisted = 0
    }
    // CoredataService
    init(with userId: String, entity: StatisticsEntity){
        self.userId = userId
        self.waterDrop = Int(entity.stat_drop)
        self.projectRegisted = Int(entity.stat_proj_reg)
        self.projectFinished = Int(entity.stat_proj_fin)
        self.projectAlerted = Int(entity.stat_proj_alert)
        self.projectExtended = Int(entity.stat_proj_ext)
        self.todoRegisted = Int(entity.stat_todo_reg)
    }
    
    //--------------------
    // function
    //--------------------
    mutating func updateWaterDrop(to newVal: Int){
        self.waterDrop = newVal
    }
    mutating func updateProjectRegist(to newVal: Int){
        self.projectRegisted = newVal
    }
    mutating func updateProjectFinish(to newVal: Int){
        self.projectFinished = newVal
    }
    mutating func updateProjectAlert(to newVal: Int){
        self.projectAlerted = newVal
    }
    mutating func updateProjectExtend(to newVal: Int){
        self.projectExtended = newVal
    }
    mutating func updateTodoRegist(to newVal: Int){
        self.todoRegisted = newVal
    }
}

//================================
// MARK: - Project for ViewModel
//================================
struct userStatProjectDTO{
    
    //--------------------
    // content
    //--------------------
    let registProject: Int
    let completeProject: Int
    let waterDrop: Int
    
    //--------------------
    // constructor
    //--------------------
    // ProjectIndexService
    init(with dto: StatProjectDTO, and count: Int){
        self.registProject = count
        self.completeProject = dto.projectFinished
        self.waterDrop = dto.waterDrop
    }
}

//================================
// MARK: - Todo
//================================
struct StatTodoDTO {
    
    //--------------------
    // content
    //--------------------
    let userId: String
    var todoRegist: Int
    var todoLimit: Int
    var projectFinish: Int
    
    //--------------------
    // constructor
    //--------------------
    // Default
    init(){
        self.userId = ""
        self.todoRegist = 0
        self.todoLimit = 0
        self.projectFinish = 0
    }
    // ProjectDetailService
    init(with userId: String, entity: StatisticsEntity) {
        self.userId = userId
        self.todoRegist = Int(entity.stat_todo_reg)
        self.todoLimit = Int(entity.stat_todo_limit)
        self.projectFinish = Int(entity.stat_proj_fin)
    }
    
    //--------------------
    // function
    //--------------------
    mutating func updateTodoRegist(with newVal: Int){
        self.todoRegist = newVal
    }
    mutating func updateTodoLimit(with newVal: Int){
        self.todoLimit = newVal
    }
    mutating func updateProjectFinished(wih newVal: Int){
        self.projectFinish = newVal
    }
}

//================================
// MARK: - Update
//================================
struct StatUpdateDTO {
    
    //--------------------
    // content
    //--------------------
    let userId: String
    var newDrop: Int?
    var newTerm: Int?
    var newLogHead: [Int:Int]?
    var newChallengeStep: [Int:Int]?
    var newMyChallenge: [Int]?
    var newProjectRegisted: Int?
    var newProjectFinished: Int?
    var newProjectAlerted: Int?
    var newProjectExtended: Int?
    var newTodoRegisted: Int?
    var newTodoLimit: Int?
    var newUploadAt: Date?
    
    //--------------------
    // constructor
    //--------------------
    init(userId: String,
         newDrop: Int? = nil,
         newTerm: Int? = nil,
         newLogHead: [Int:Int]? = nil,
         newChallengeStep: [Int:Int]? = nil,
         newMyChallenge: [Int]? = nil,
         newProjectRegisted: Int? = nil,
         newProjectFinished: Int? = nil,
         newProjectAlerted: Int? = nil,
         newProjectExtended: Int? = nil,
         newTodoRegisted: Int? = nil,
         newTodoLimit: Int? = nil,
         newUploadAt: Date? = nil
    ){
        self.userId = userId
        self.newDrop = newDrop
        self.newTerm = newTerm
        self.newLogHead = newLogHead
        self.newChallengeStep = newChallengeStep
        self.newMyChallenge = newMyChallenge
        self.newProjectRegisted = newProjectRegisted
        self.newProjectFinished = newProjectFinished
        self.newProjectAlerted = newProjectAlerted
        self.newProjectExtended = newProjectExtended
        self.newTodoRegisted = newTodoRegisted
        self.newTodoLimit = newTodoLimit
        self.newUploadAt = newUploadAt
    }
}

//================================
// MARK: - Type
//================================
enum DTOType {
    case login
    case home
    case challenge
    case project
    case center
    case todo
}
