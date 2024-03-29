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

    var challengeId: Int
    let userId: String
    let title: String
    let desc: String
    let goal: Int
    let type: ChallengeType
    let reward: Int
    let step: Int
    let version: Int
    
    let status: Bool
    let lock: Bool
    let progress: Int
    let selectStatus: Bool
    let selectedAt: Date
    let unselectedAt: Date
    let finishedAt: Date
    
    init(
        challengeId: Int,
        userId: String,
        title: String,
        desc: String,
        goal: Int,
        type: ChallengeType,
        reward: Int,
        step: Int,
        version: Int,
        status: Bool,
        lock: Bool,
        progress: Int,
        selectStatus: Bool,
        selectedAt: Date,
        unselectedAt: Date,
        finishedAt: Date)
    {
        self.challengeId = challengeId
        self.userId = userId
        self.title = title
        self.desc = desc
        self.goal = goal
        self.type = type
        self.reward = reward
        self.step = step
        self.version = version
        self.status = status
        self.lock = lock
        self.progress = progress
        self.selectStatus = selectStatus
        self.selectedAt = selectedAt
        self.unselectedAt = unselectedAt
        self.finishedAt = finishedAt
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
