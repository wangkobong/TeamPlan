//
//  ChallengeDTO.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/08/26.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation

//============================
// MARK: Legacy
//============================
struct ChallengeCardResDTO{
    // id
    let id: Int
    
    // category
    let type: ChallengeType
    
    // content
    let title: String
    let desc: String
    let goal: Int
    let reward: Int
    
    // Constructor
    init(chlgObject: ChallengeObject){
        self.id = chlgObject.chlg_id
        self.type = ChallengeType(rawValue: chlgObject.chlg_type.rawValue) ?? .unknownType
        self.title = chlgObject.chlg_title
        self.desc = chlgObject.chlg_desc
        self.goal = Int(chlgObject.chlg_goal)
        self.reward = Int(chlgObject.chlg_reward)
    }
}

struct MyChallengeDetailResDTO{
    // categoory
    let type: ChallengeType
    
    // content
    let title: String
    let desc: String
    let goal: Int
    let progress: Int
    
    // Constructor
    // myChallenge
    init(chlgObject: ChallengeObject, userProgress: Int){
        self.type = ChallengeType(rawValue: chlgObject.chlg_type.rawValue) ?? .unknownType
        self.title = chlgObject.chlg_title
        self.desc = chlgObject.chlg_desc
        self.goal = Int(chlgObject.chlg_goal)
        self.progress = userProgress
    }
}

struct ChallengeDetailResDTO{
    // content
    let title: String
    let desc: String
    let prevChlg: String
    
    // status
    let isComplete: Bool
    let isSelected: Bool
    let isUnlock: Bool
    
    init(chlgObject: ChallengeObject, prevChallenge: String) {
        self.title = chlgObject.chlg_title
        self.desc = chlgObject.chlg_desc
        self.prevChlg = prevChallenge
        self.isComplete = chlgObject.chlg_status
        self.isSelected = chlgObject.chlg_selected
        self.isUnlock = chlgObject.chlg_lock
    }
}

struct ChallengeStatusReqDTO{
    // id
    let chlg_id: Int
    
    // status
    let chlg_step: Int
    let chlg_selected: Bool
    let chlg_status: Bool
    let chlg_lock: Bool
    
    init(chlgObject: ChallengeObject, myChlg: Bool){
        self.chlg_id = chlgObject.chlg_id
        self.chlg_step = chlgObject.chlg_step
        self.chlg_selected = myChlg
        self.chlg_status = chlgObject.chlg_status
        self.chlg_lock = chlgObject.chlg_lock
    }
}

//============================
// MARK: Updated
//============================
// MyChallenge
struct MyChallengeDTO {
    // id
    let cahllengeID: Int
    
    // category
    let type: ChallengeType
    
    // content
    let title: String
    let desc: String
    let goal: Int
    let progress: Int
    
    // Constructor
    init(chlgObject: ChallengeObject, userProgress: Int){
        self.cahllengeID = chlgObject.chlg_id
        self.type = chlgObject.chlg_type
        self.title = chlgObject.chlg_title
        self.desc = chlgObject.chlg_desc
        self.goal = Int(chlgObject.chlg_goal)
        self.progress = userProgress
    }
}

// Total Challenge
struct ChallengeDTO{
    // id
    let id: Int
    
    // category
    let type: ChallengeType
    
    // Target content
    let title: String
    let desc: String
    let goal: Int
    let reward: Int
    
    // Prev content
    let prevId: Int?
    let prevTitle: String?
    let prevDesc: String?
    let prevGoal: Int?
    
    // status
    let isComplete: Bool
    let isSelected: Bool
    let isUnlock: Bool
    
    // Constructor
    init(from object: ChallengeObject, prev prevObject: ChallengeObject){
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
        self.isComplete = object.chlg_status
        self.isSelected = object.chlg_selected
        self.isUnlock = object.chlg_lock
    }
    
    init(from object: ChallengeObject){
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
        self.isComplete = object.chlg_status
        self.isSelected = object.chlg_selected
        self.isUnlock = object.chlg_lock
    }
}

// Reward Challenge
struct ChallengeRewardDTO {
    // id
    let id: Int
    
    // content
    let title: String
    let desc: String
    let type: ChallengeType
    let goal: Int
    
    // Constructor
    init(from object: ChallengeObject) {
        self.id = object.chlg_id
        self.title = object.chlg_title
        self.desc = object.chlg_desc
        self.type = object.chlg_type
        self.goal = object.chlg_goal
    }
}

// Update Challenge
struct ChallengeStatusDTO {
    // id
    let chlg_id: Int
    
    // status
    let chlg_selected: Bool?
    let chlg_status: Bool?
    let chlg_lock: Bool?
    
    // maintenance
    let chlg_selected_at: Date?
    let chlg_unselected_at: Date?
    let chlg_finished_at: Date?
    
    // ===== MyChallenge Select
    init(target challengeId: Int, select myChallenge: Bool, selectTime time: Date){
        self.chlg_id = challengeId
        self.chlg_selected = myChallenge
        self.chlg_selected_at = time
        
        // unchanged
        self.chlg_status = nil
        self.chlg_lock = nil
        self.chlg_unselected_at = nil
        self.chlg_finished_at = nil
    }
    
    // ===== MyChallenge Disable
    init(target challengeId: Int, select myChallenge: Bool, disableTime time: Date){
        self.chlg_id = challengeId
        self.chlg_selected = myChallenge
        self.chlg_unselected_at = time
        
        // unchanged
        self.chlg_status = nil
        self.chlg_lock = nil
        self.chlg_selected_at = nil
        self.chlg_finished_at = nil
    }
    
    // ===== Challenge Complete
    init(target challengeId: Int, when completeTime: Date){
        self.chlg_id = challengeId
        self.chlg_selected = false
        self.chlg_status = true
        self.chlg_unselected_at = completeTime
        self.chlg_finished_at = completeTime
        
        // unchanged
        self.chlg_lock = nil
        self.chlg_selected_at = nil
    }
    
    // ===== unlock
    init(target challengeId: Int, status unlock: Bool){
        self.chlg_id = challengeId
        self.chlg_lock = unlock
        
        // unchanged
        self.chlg_selected = nil
        self.chlg_status = nil
        self.chlg_selected_at = nil
        self.chlg_unselected_at = nil
        self.chlg_finished_at = nil
    }
}
