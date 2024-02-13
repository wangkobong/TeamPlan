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
struct MyChallengeDTO: Hashable, Identifiable {

    //--------------------
    // content
    //--------------------
    let id = UUID().uuidString
    var challengeID: Int
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
    // for index (essential)
    let id: Int
    let type: ChallengeType
    let title: String
    let isComplete: Bool
    let isSelected: Bool
    let isUnlock: Bool
    
    // for detail (optional)
    let desc: String?
    let goal: Int?
    let reward: Int?
    let step: Int?
    let completeAt: Date?
    
    let prevId: Int?
    let prevTitle: String?
    let prevDesc: String?
    let prevGoal: Int?
    
    // for log (optional)
    let setMyChallengeAt: Date?
    let disableMyChallengeAt: Date?
    
    //--------------------
    // constructor
    //--------------------
    // for index
    init(forIndex object: ChallengeObject){
        self.id = object.chlg_id
        self.type = object.chlg_type
        self.title = object.chlg_title
        self.isComplete = object.chlg_status
        self.isSelected = object.chlg_selected
        self.isUnlock = object.chlg_lock
        
        self.desc = nil
        self.goal = nil
        self.reward = nil
        self.step = nil
        self.completeAt = nil
        
        self.prevId = nil
        self.prevTitle = nil
        self.prevDesc = nil
        self.prevGoal = nil
        
        self.setMyChallengeAt = nil
        self.disableMyChallengeAt = nil
    }
    
    // for detail
    init(forDetail object: ChallengeObject, previous prevObject: ChallengeObject? = nil){
        self.id = object.chlg_id
        self.type = object.chlg_type
        self.title = object.chlg_title
        self.isComplete = object.chlg_status
        self.isSelected = object.chlg_selected
        self.isUnlock = object.chlg_lock
        
        self.desc = object.chlg_desc
        self.goal = Int(object.chlg_goal)
        self.reward = Int(object.chlg_reward)
        self.step = object.chlg_step
        self.completeAt = object.chlg_finished_at
        
        self.prevId = prevObject?.chlg_id
        self.prevTitle = prevObject?.chlg_title
        self.prevDesc = prevObject?.chlg_desc
        self.prevGoal = prevObject?.chlg_goal
        
        self.setMyChallengeAt = object.chlg_selected_at
        self.disableMyChallengeAt = object.chlg_unselected_at
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
struct ChallengeUpdateDTO {
    
    //--------------------
    // content
    //--------------------
    let challengeId: Int
    let userId: String
    
    var newSelected: Bool?
    var newStatus: Bool?
    var newLock: Bool?
    var newSelectedAt: Date?
    var newUnSelectedAt: Date?
    var newFinishedAt: Date?
    
    //--------------------
    // constructor
    //--------------------
    init(challengeId: Int, userId: String,
         newSelected: Bool? = nil,
         newStatus: Bool? = nil,
         newLock: Bool? = nil,
         newSelectedAt: Date? = nil,
         newUnSelectedAt: Date? = nil,
         newFinishedAt: Date? = nil)
    {
        self.challengeId = challengeId
        self.userId = userId
        self.newSelected = newSelected
        self.newStatus = newStatus
        self.newLock = newLock
        self.newSelectedAt = newSelectedAt
        self.newUnSelectedAt = newUnSelectedAt
        self.newFinishedAt = newFinishedAt
    }
}
