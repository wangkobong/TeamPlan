//
//  ChallengeDTO.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/08/26.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation

//============================
// MARK: MyChallenges
//============================
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

//============================
// MARK: Challenges
//============================
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
    let step: Int?
    let isComplete: Bool?
    let isSelected: Bool?
    let isUnlock: Bool?
    
    // Statistics
    let setMyChallengeAt: Date?
    let disableMyChallengeAt: Date?
    let completeAt: Date?
    
    // Constructor
    // Detail
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
        self.step = object.chlg_step
        self.isComplete = object.chlg_status
        self.isSelected = object.chlg_selected
        self.isUnlock = object.chlg_lock
        self.setMyChallengeAt = object.chlg_selected_at
        self.disableMyChallengeAt = object.chlg_unselected_at
        self.completeAt = object.chlg_finished_at
    }
    
    // Total
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
        self.step = object.chlg_step
        self.isComplete = object.chlg_status
        self.isSelected = object.chlg_selected
        self.isUnlock = object.chlg_lock
        self.setMyChallengeAt = object.chlg_selected_at
        self.disableMyChallengeAt = object.chlg_unselected_at
        self.completeAt = object.chlg_finished_at
    }
}

// Reward Challenge
struct ChallengeRewardDTO {
    // content
    let title: String
    let desc: String
    let type: ChallengeType
    let reward: Int
    
    // Statistics
    let setMyChallengeAt: Date
    let completeAt: Date
    
    // Constructor
    init(from object: ChallengeObject, to nextObject: ChallengeObject) {
        self.title = nextObject.chlg_title
        self.desc = nextObject.chlg_desc
        self.type = nextObject.chlg_type
        self.reward = object.chlg_reward
        self.setMyChallengeAt = object.chlg_selected_at
        self.completeAt = object.chlg_finished_at
    }
}

//============================
// MARK: Challenges Status
//============================
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
