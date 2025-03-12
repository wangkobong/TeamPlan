//
//  HomeDataModel.swift
//  투두팡
//
//  Created by sungyeon kim on 3/12/25.
//  Copyright © 2025 team1os. All rights reserved.
//

import Foundation

struct HomeData: Codable {
    let userName: String
    let finishedProjects: Int
    let registeredProjects: Int
    let categories: [String: String] 
    let popularChallenges: [Challenge]
}
