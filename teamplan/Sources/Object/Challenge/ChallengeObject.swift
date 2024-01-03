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
public struct ChallengeObject: Hashable {

    //--------------------
    // content
    //--------------------
    var chlg_id: Int
    var chlg_user_id: String
    
    let chlg_type: ChallengeType
    let chlg_title: String
    let chlg_desc: String
    let chlg_goal: Int
    let chlg_reward: Int
    let chlg_step: Int
    let chlg_selected: Bool
    let chlg_status: Bool
    var chlg_lock: Bool
    let chlg_selected_at: Date
    let chlg_unselected_at: Date
    let chlg_finished_at: Date
    
    //--------------------
    // constructor
    //--------------------
    // Coredata
    init?(chlgEntity: ChallengeEntity) {
        guard let chlg_user_id = chlgEntity.chlg_user_id,
              let chlg_type = ChallengeType(rawValue: Int(chlgEntity.chlg_type)),
              let chlg_title = chlgEntity.chlg_title,
              let chlg_desc = chlgEntity.chlg_desc,
              let chlg_selected_at = chlgEntity.chlg_selected_at,
              let chlg_unselected_at = chlgEntity.chlg_unselected_at,
              let chlg_finished_at = chlgEntity.chlg_finished_at
        else {
            return nil
        }
        // Assigning values
        self.chlg_id = Int(chlgEntity.chlg_id)
        self.chlg_user_id = chlg_user_id
        self.chlg_type = chlg_type
        self.chlg_title = chlg_title
        self.chlg_desc = chlg_desc
        self.chlg_goal = Int(chlgEntity.chlg_goal)
        self.chlg_reward = Int(chlgEntity.chlg_reward)
        self.chlg_step = Int(chlgEntity.chlg_step)
        self.chlg_selected = chlgEntity.chlg_selected
        self.chlg_status = chlgEntity.chlg_status
        self.chlg_lock = chlgEntity.chlg_lock
        self.chlg_selected_at = chlg_selected_at
        self.chlg_unselected_at = chlg_unselected_at
        self.chlg_finished_at = chlg_finished_at
    }
    
    // Firestore
    init?(challengeData: [String : Any]){
        guard let chlg_id = challengeData["chlg_id"] as? Int,
              let chlg_type = challengeData["chlg_type"] as? Int,
              let chlg_title = challengeData["chlg_title"] as? String,
              let chlg_desc = challengeData["chlg_desc"] as? String,
              let chlg_goal = challengeData["chlg_goal"] as? Int,
              let chlg_reward = challengeData["chlg_reward"] as? Int,
              let chlg_step = challengeData["chlg_step"] as? Int
        else {
            return nil
        }
        // Assigning values
        self.chlg_id = chlg_id
        self.chlg_user_id = ""
        self.chlg_type = ChallengeType(rawValue: chlg_type)!
        self.chlg_title = chlg_title
        self.chlg_desc = chlg_desc
        self.chlg_goal = chlg_goal
        self.chlg_reward = chlg_reward
        self.chlg_step = chlg_step
        self.chlg_selected = false
        self.chlg_status = false
        self.chlg_lock = true
        self.chlg_selected_at = Date()
        self.chlg_unselected_at = Date()
        self.chlg_finished_at = Date()
    }
    
    //--------------------
    // constructor
    //--------------------
    mutating func updateLock(with newVal: Bool){
        self.chlg_lock = newVal
    }
    mutating func addUserId(with userId: String){
        self.chlg_user_id = userId
    }
}

//============================
// MARK: Type
//============================
enum ChallengeType: Int{
    case onboarding = 0
    case serviceTerm = 1
    case totalTodo = 2
    case projectAlert = 3
    case projectFinish = 4
    case waterDrop = 5
    case unknownType = 6
}
