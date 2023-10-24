//
//  StatisticsCenter.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/10/10.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation

final class StatisticsCenter{
    
    var identifier: String
    let statCD: StatisticsServicesCoredata
    
    init(identifier: String){
        self.identifier = identifier
        self.statCD = StatisticsServicesCoredata()
    }
    
    //================================
    // MARK: UserProgres
    //================================
    func returnUserProgress(challengeType: ChallengeType,
                            result: @escaping(Result<Int, Error>) -> Void) {
        
        statCD.getStatCoredata(identifier: self.identifier) { getRes in
            switch getRes{
            case .success(let reqStat):
                
                // determine UserProgress based on Challenge Type
                let progress = self.userProgress(for: challengeType, with: reqStat)
                
                // Exception Handling: Invalid Type
                if progress == 0 {
                    return result(.failure(StatCenterError.InvalidType))
                } else {
                    return result(.success(progress))
                }
                
            // Exception Handling: Failed to get Statistics
            case .failure(let error):
                return result(.failure(error))
            }
        }
    }
    
    private func userProgress(for challengeType: ChallengeType, with stat: StatisticsObject) -> Int {
            switch challengeType {
            case .onboarding:
                return 1
            case .serviceTerm:
                return stat.stat_term
            case .totalTodo:
                return stat.stat_todo_reg
            case .projectRegist:
                return stat.stat_proj_reg
            case .projectFinish:
                return stat.stat_proj_fin
            case .waterDrop:
                return stat.stat_drop
            case .unknownType:
                return 0
            }
        }
    
    //===============================
    // MARK: - Exception
    //===============================
    enum StatCenterError: LocalizedError {
        case InvalidType
        
        var errorDescription: String?{
            switch self {
            case .InvalidType:
                return "Invalid Challenge Type"
            }
        }
    }
}
