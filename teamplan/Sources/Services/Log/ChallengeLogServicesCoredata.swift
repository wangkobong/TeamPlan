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
    let util = Utilities()
    let cd = CoreDataManager.shared
    var context: NSManagedObjectContext {
        return cd.context
    }
    
    //================================
    // MARK: - Set ChallengeLog
    //================================
    func setLog(with log: ChallengeLog) throws {
        
        // Create Entity & Set Data
        try setLogEntity(with: log)
        try context.save()
    }
    // Support Function
    private func setLogEntity(with log: ChallengeLog) throws {
        
        // Create LogEntity
        let log_complete_string = try util.convertToJSON(data: log.log_complete)
        let logEntity = ChallengeLogEntity(context: context)
        
        logEntity.log_user_id = log.log_user_id
        logEntity.log_complete = log_complete_string
        logEntity.log_update_at = log.log_update_at
    }
    
    //================================
    // MARK: - Get ChallengeLog
    //================================
    func getLog(with userId: String) throws -> ChallengeLog {
        
        // parameter setting
        let fetchReq: NSFetchRequest<ChallengeLogEntity> = ChallengeLogEntity.fetchRequest()
        
        // Request Query
        fetchReq.predicate = NSPredicate(format: "log_user_id == %@", userId)
        fetchReq.fetchLimit = 1
        
        // Search Data
        guard let entity = try context.fetch(fetchReq).first else {
            throw ChallengeLogErrorCD.ChallengeLogRetrievalByIdentifierFailed
        }
        // Convert Data
        let log = try util.convertFromJSON(jsonString: entity.log_complete, type: [Int : Date].self)
        
        // Convert to Log & Get
        guard let challengeLog = ChallengeLog(from: entity, log: log) else {
            throw ChallengeLogErrorCD.UnexpectedConvertError
        }
        return challengeLog
    }
    
    //================================
    // MARK: - Update ChallengeLog
    //================================
    func updateLog(with userId: String, updatedLog: [Int:Date], updatedAt: Date) throws {
        
        // parameter setting
        let fetchReq: NSFetchRequest<ChallengeLogEntity> = ChallengeLogEntity.fetchRequest()
        
        // Request Query
        fetchReq.predicate = NSPredicate(format: "log_user_id == %@", userId)
        fetchReq.fetchLimit = 1
        
        // Search Data
        guard let entity = try context.fetch(fetchReq).first else {
            throw ChallengeLogErrorCD.ChallengeLogRetrievalByIdentifierFailed
        }
        // Convert to Data
        let log = try util.convertFromJSON(jsonString: entity.log_complete, type: [Int : Date].self)
        
        //TODO: Update Data
        
        // Convert to JSON
        let log_json = try util.convertToJSON(data: log)
        
        // Update Data
        entity.log_complete = log_json
        entity.log_update_at = updatedAt
        try context.save()
    }
    
    //================================
    // MARK: - Delete ChallengeLog
    //================================
    func deleteLog(with userId: String) throws {
        
        // parameter setting
        let fetchReq: NSFetchRequest<ChallengeLogEntity> = ChallengeLogEntity.fetchRequest()
        
        // Request Query
        fetchReq.predicate = NSPredicate(format: "log_user_id == %@", userId)
        fetchReq.fetchLimit = 1
        
        // Search Data
        guard let entity = try context.fetch(fetchReq).first else {
            throw ChallengeLogErrorCD.ChallengeLogRetrievalByIdentifierFailed
        }
        // Delete Data
        context.delete(entity)
        try context.save()
    }
}

//===============================
// MARK: - Exception
//===============================
enum ChallengeLogErrorCD: LocalizedError {
    case UnexpectedSerializeError
    case UnexpectedDeserializeError
    case UnexpectedConvertError
    case ChallengeLogRetrievalByIdentifierFailed
    
    var errorDescription: String?{
        switch self {
        case .UnexpectedSerializeError:
            return "Coredata: There was an unexpected error while Serialize 'ChallengeLog' details"
        case .UnexpectedDeserializeError:
            return "Coredata: There was an unexpected error while Deserialize 'ChallengeLog' details"
        case .UnexpectedConvertError:
            return "Coredata: There was an unexpected error while Convert 'ChallengeLog' details"
        case .ChallengeLogRetrievalByIdentifierFailed:
            return "CoreData: Unable to retrieve 'ChallengeLog' data using the provided identifier."
        }
    }
}
