//
//  StatisticsObject.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/10/10.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation

// MARK: - Object
struct StatisticsObject{
    
    let userId: String
    let term: Int
    let drop: Int
    let totalRegistedProjects: Int
    let totalFinishedProjects: Int
    let totalFailedProjects: Int
    let totalAlertedProjects: Int
    let totalExtendedProjects: Int
    let totalRegistedTodos: Int
    let totalFinishedTodos: Int
    let challengeStepStatus: [Int : Int]
    let mychallenges: [Int]
    var syncedAt: Date
    
    init(
        userId: String,
        term: Int,
        drop: Int,
        totalRegistedProjects: Int,
        totalFinishedProjects: Int,
        totalFailedProjects: Int,
        totalAlertedProjects: Int,
        totalExtendedProjects: Int,
        totalRegistedTodos: Int,
        totalFinishedTodos: Int,
        challengeStepStatus: [Int : Int],
        mychallenges: [Int],
        syncedAt: Date)
    {
        self.userId = userId
        self.term = term
        self.drop = drop
        self.totalRegistedProjects = totalRegistedProjects
        self.totalFinishedProjects = totalFinishedProjects
        self.totalFailedProjects = totalFailedProjects
        self.totalAlertedProjects = totalAlertedProjects
        self.totalExtendedProjects = totalExtendedProjects
        self.totalRegistedTodos = totalRegistedTodos
        self.totalFinishedTodos = totalFinishedTodos
        self.challengeStepStatus = challengeStepStatus
        self.mychallenges = mychallenges
        self.syncedAt = syncedAt
    }
    
    init() {
        self.userId = ""
        self.term = 0
        self.drop = 0
        self.totalRegistedProjects = 0
        self.totalFinishedProjects = 0
        self.totalFailedProjects = 0
        self.totalAlertedProjects = 0
        self.totalExtendedProjects = 0
        self.totalRegistedTodos = 0
        self.totalFinishedTodos = 0
        self.challengeStepStatus = [:]
        self.mychallenges = []
        self.syncedAt = Date()
    }
}

// MARK: - Enum
enum DTOType {
    case challenge
}
