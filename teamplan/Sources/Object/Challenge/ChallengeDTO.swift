//
//  ChallengeDTO.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/08/26.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation

//============================
// MARK: Card - Home/Challenge
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
