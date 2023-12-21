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
    // MARK: - Parameter
    //================================
    let statCD = StatisticsServicesCoredata()

    let userId: String
    
    var statDTO: StatCenterDTO
    
    //===============================
    // MARK: - Constructor
    //===============================
    init(with userId: String){
        self.userId = userId
        self.statDTO = StatCenterDTO()
    }
    
    func readyCenter() throws {
        guard let dto = try statCD.getStatisticsForDTO(with: userId, type: .center) as? StatCenterDTO else {
            throw StatCenterError.UnexpectedGetError
        }
        self.statDTO = dto
    }
    
    //================================
    // MARK: Function
    //================================
    func getUserProgress(type: ChallengeType) -> Int {
        switch type {
        case .onboarding:
            return 1
        case .serviceTerm:
            return statDTO.stat_term
        case .totalTodo:
            return statDTO.stat_todo_reg
        case .projectAlert:
            return statDTO.stat_proj_alert
        case .projectFinish:
            return statDTO.stat_proj_fin
        case .waterDrop:
            return statDTO.stat_drop
        case .unknownType:
            return 0
        }
    }
}

//===============================
// MARK: - Exception
//===============================
enum StatCenterError: LocalizedError {
    case UnexpectedGetError
    
    var errorDescription: String?{
        switch self {
        case .UnexpectedGetError:
            return "Service: There was an unexpected error while Get Statistics in 'StatisticsCenter'"
        }
    }
}
