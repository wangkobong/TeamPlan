//
//  ChallengeLogServicesCoredata.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/10/20.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation
import CoreData

final class ChallengeLogServicesCoredata{
    
    //================================
    // MARK: - CoreData Setting
    //================================
    let cd = CoreDataManager.shared
    var context: NSManagedObjectContext {
        return cd.context
    }
    
    //================================
    // MARK: - Set ChallengeLog
    //================================
    func setChallengeLog(reqLog: ChallengeLog,
                         result: @escaping(Result<String, Error>) -> Void) {
        
        // Create new LogEntity
        let logEntity = ChallengeLogEntity(context: context)
        
        // Set ChallengeLog Info
        logEntity.log_user_id = reqLog.log_user_id
        logEntity.log_complete = reqLog.log_complete as NSObject
        logEntity.log_update_at = reqLog.log_update_at
        
        // Set Log
        do {
            try context.save()
            return result(.success("Successfully Set ChallengeLog"))
        } catch {
            return result(.failure(ChallengeLogError.SetFailed))
        }
    }
    
    //================================
    // MARK: - Update ChallengeLog
    //================================
    
    
    //===============================
    // MARK: - Exception
    //===============================
    enum ChallengeLogError: LocalizedError {
        case UnknownFetchFailed
        case IdentifierFetchFailed
        case SetFailed
        case UpdateFailed
        
        var errorDescription: String? {
            switch self {
            case .UnknownFetchFailed:
                return "Failed to Fetch ChallengeLog by Unknown Reason"
            case .IdentifierFetchFailed:
                return "Failed to Fetch ChallengeLog by identifier"
            case .SetFailed:
                return "Failed to Set ChallengeLog at Coredata"
            case .UpdateFailed:
                return "Failed to Update ChallengeLog at Coredata"
            }
        }
    }
}
