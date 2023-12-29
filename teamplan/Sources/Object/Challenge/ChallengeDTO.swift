//
//  ChallengeDTO.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/08/26.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation

//============================
// MARK: MyChallenge
//============================
struct MyChallengeDTO: Hashable {

    //--------------------
    // content
    //--------------------
    let challengeID: Int
    let type: ChallengeType
    let title: String
    let desc: String
    let goal: Int
    let progress: Int
    
    //--------------------
    // constructor
    //--------------------
    init(with object: ChallengeObject, and userProgress: Int){
        self.challengeID = object.chlg_id
        self.type = object.chlg_type
        self.title = object.chlg_title
        self.desc = object.chlg_desc
        self.goal = Int(object.chlg_goal)
        self.progress = userProgress
    }
}

//============================
// MARK: Challenge
//============================
struct ChallengeDTO{

    //--------------------
    // content
    //--------------------
    let id: Int
    let type: ChallengeType
    let title: String
    let desc: String
    let goal: Int
    let reward: Int
    let step: Int?
    let isComplete: Bool?
    let isSelected: Bool?
    let isUnlock: Bool?
    let setMyChallengeAt: Date?
    let disableMyChallengeAt: Date?
    let completeAt: Date?
    let prevId: Int?
    let prevTitle: String?
    let prevDesc: String?
    let prevGoal: Int?
    
    //--------------------
    // constructor
    //--------------------
    // Detail
    init(with object: ChallengeObject, and prevObject: ChallengeObject){
        self.id = object.chlg_id
        self.type = object.chlg_type
        self.title = object.chlg_title
        self.desc = object.chlg_desc
        self.goal = Int(object.chlg_goal)
        self.reward = Int(object.chlg_reward)
        self.prevId = prevObject.chlg_id
        self.prevTitle = prevObject.chlg_title
        self.prevDesc = prevObject.chlg_desc
        self.prevGoal = prevObject.chlg_goal
        self.step = object.chlg_step
        self.isComplete = object.chlg_status
        self.isSelected = object.chlg_selected
        self.isUnlock = object.chlg_lock
        self.setMyChallengeAt = object.chlg_selected_at
        self.disableMyChallengeAt = object.chlg_unselected_at
        self.completeAt = object.chlg_finished_at
    }
    
    // Total
    init(with object: ChallengeObject){
        self.id = object.chlg_id
        self.type = object.chlg_type
        self.title = object.chlg_title
        self.desc = object.chlg_desc
        self.goal = Int(object.chlg_goal)
        self.reward = Int(object.chlg_reward)
        self.prevId = nil
        self.prevTitle = nil
        self.prevDesc = nil
        self.prevGoal = nil
        self.step = object.chlg_step
        self.isComplete = object.chlg_status
        self.isSelected = object.chlg_selected
        self.isUnlock = object.chlg_lock
        self.setMyChallengeAt = object.chlg_selected_at
        self.disableMyChallengeAt = object.chlg_unselected_at
        self.completeAt = object.chlg_finished_at
    }
}

//============================
// MARK: Reward
//============================
struct ChallengeRewardDTO {

    //--------------------
    // content
    //--------------------
    let title: String
    let desc: String
    let type: ChallengeType
    let reward: Int
    let setMyChallengeAt: Date
    let completeAt: Date
    
    //--------------------
    // constructor
    //--------------------
    init(with object: ChallengeObject, and nextObject: ChallengeObject) {
        self.title = nextObject.chlg_title
        self.desc = nextObject.chlg_desc
        self.type = nextObject.chlg_type
        self.reward = object.chlg_reward
        self.setMyChallengeAt = object.chlg_selected_at
        self.completeAt = object.chlg_finished_at
    }
}

//============================
// MARK: Update
//============================
struct ChallengeStatusDTO {
    
    //--------------------
    // content
    //--------------------
    let chlg_id: Int
    let chlg_user_id: String
    var chlg_selected: Bool
    var chlg_status: Bool
    var chlg_lock: Bool
    var chlg_selected_at: Date
    var chlg_unselected_at: Date
    var chlg_finished_at: Date
    
    //--------------------
    // constructor
    //--------------------
    init(with object: ChallengeObject){
        self.chlg_id = object.chlg_id
        self.chlg_user_id = object.chlg_user_id
        self.chlg_selected = object.chlg_selected
        self.chlg_status = object.chlg_status
        self.chlg_lock = object.chlg_lock
        self.chlg_selected_at = object.chlg_selected_at
        self.chlg_unselected_at = object.chlg_unselected_at
        self.chlg_finished_at = object.chlg_finished_at
    }
    
    //--------------------
    // func
    //--------------------
    mutating func updateSelected(with newVal: Bool){
        self.chlg_selected = newVal
    }
    mutating func updateStatus(with newVal: Bool){
        self.chlg_status = newVal
    }
    mutating func updateLock(with newVal: Bool){
        self.chlg_lock = newVal
    }
    mutating func updateSelectedAt(with newVal: Date){
        self.chlg_selected_at = newVal
    }
    mutating func updateUnselectedAt(with newVal: Date){
        self.chlg_unselected_at = newVal
    }
    mutating func updateFinishedAt(with newVal: Date){
        self.chlg_finished_at = newVal
    }
}
