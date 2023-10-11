//
//  ChallengeObject.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/08/26.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation

//============================
// MARK: Entity
//============================
struct ChallengeObject{
    // id
    let chlg_id: Int
    
    // category
    let chlg_type: ChallengeType
    
    // content
    let chlg_title: String
    let chlg_desc: String
    let chlg_goal: Int
    let chlg_reward: Int
    
    // status
    let chlg_step: Int
    let chlg_selected: Bool
    let chlg_status: Bool
    let chlg_lock: Bool
    
    // maintenance
    let chlg_selected_at: Date
    let chlg_unselected_at: Date
    let chlg_finished_at: Date
    
    // Constructor
    // Get Coredata
    init(chlgEntity: ChallengeEntity) {
        self.chlg_id = Int(chlgEntity.chlg_id)
        self.chlg_type = ChallengeType(rawValue: Int(chlgEntity.chlg_type)) ?? .unknownType
        self.chlg_title = chlgEntity.chlg_title!
        self.chlg_desc = chlgEntity.chlg_desc!
        self.chlg_goal = Int(chlgEntity.chlg_goal)
        self.chlg_reward = Int(chlgEntity.chlg_reward)
        self.chlg_step = Int(chlgEntity.chlg_step)
        self.chlg_selected = chlgEntity.chlg_selected
        self.chlg_status = chlgEntity.chlg_status
        self.chlg_lock = chlgEntity.chlg_lock
        self.chlg_selected_at = chlgEntity.chlg_selected_at ?? Date()
        self.chlg_unselected_at = chlgEntity.chlg_unselected_at ?? Date()
        self.chlg_finished_at = chlgEntity.chlg_finished_at ?? Date()
    }
    
    // Get Dummy
    init(chlg_id: Int64, chlg_type: ChallengeType, chlg_title: String, chlg_desc: String, chlg_goal: Int64, chlg_reward: Int, chlg_step: Int, chlg_selected: Bool, chlg_status: Bool, chlg_lock: Bool, chlg_selected_at: Date, chlg_unselected_at: Date, chlg_finished_at: Date) {
        self.chlg_id = Int(chlg_id)
        self.chlg_type = chlg_type
        self.chlg_title = chlg_title
        self.chlg_desc = chlg_desc
        self.chlg_goal = Int(chlg_goal)
        self.chlg_reward = chlg_reward
        self.chlg_step = chlg_step
        self.chlg_selected = chlg_selected
        self.chlg_status = chlg_status
        self.chlg_lock = chlg_lock
        self.chlg_selected_at = chlg_selected_at
        self.chlg_unselected_at = chlg_unselected_at
        self.chlg_finished_at = chlg_finished_at
    }
}

enum ChallengeType: Int{
    case onboarding = 0
    case serviceTerm = 1
    case totalTodo = 2
    case projectRegist = 3
    case projectFinish = 4
    case waterDrop = 5
    case unknownType = 6
}
