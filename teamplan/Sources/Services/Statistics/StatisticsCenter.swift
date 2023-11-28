//
//  StatisticsCenter.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/10/10.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation

final class StatisticsCenter{
    
    //================================
    // MARK: UserProgres
    //================================
    func userProgress(from type: ChallengeType, from stat: StatisticsDTO) -> Int {
        switch type {
        case .onboarding:
            return 1
        case .serviceTerm:
            return stat.stat_term
        case .totalTodo:
            return stat.stat_todo_reg
        case .projectAlert:
            return stat.stat_proj_reg
        case .projectFinish:
            return stat.stat_proj_fin
        case .waterDrop:
            return stat.stat_drop
        case .unknownType:
            return 0
        }
    }
}
