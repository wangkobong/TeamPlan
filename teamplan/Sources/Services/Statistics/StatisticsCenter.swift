//
//  StatisticsCenter.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/10/10.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation

final class StatisticsCenter{
    
    let statCD = StatisticsServiceCoredata()
    
    //================================
    // MARK:
    //================================
    func returnUserProgress(challengeType: ChallengeType) -> Int{
        
        let userStat = statCD.getStatCoredata()
        //TODO: Exception Handling - failed to get 'userStat'
        
        switch challengeType {
        case .onboarding:
            return 1
        case .serviceTerm:
            return userStat.stat_term
        case .totalTodo:
            return userStat.stat_todo_reg
        case .projectRegist:
            return userStat.stat_proj_reg
        case .projectFinish:
            return userStat.stat_proj_fin
        case .waterDrop:
            return userStat.stat_drop
        case .unknownType:
            return 0
        }
    }
}
