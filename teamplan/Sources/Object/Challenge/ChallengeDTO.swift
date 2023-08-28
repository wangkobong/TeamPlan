//
//  ChallengeDTO.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/08/26.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation

//============================
// MARK: Home - Local
//============================
struct ChallengeHomeLocalResDTO{
    // category
    let type: ChallengeType
    
    // content
    let title: String
    let desc: String
    let goal: Int64
    let reward: Int
    
    // Constructor
    init(from chlgObject: ChallengeObject){
        self.type = ChallengeType(rawValue: chlgObject.chlg_type.rawValue) ?? .unkown
        self.title = chlgObject.chlg_title
        self.desc = chlgObject.chlg_desc
        self.goal = Int64(chlgObject.chlg_goal)
        self.reward = Int(chlgObject.chlg_reward)
    }
}
