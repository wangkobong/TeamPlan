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
    func setLog(reqLog: ChallengeLog) throws {
        
        // Create Entity & Set Data
        try setLogEntity(from: reqLog)
        try context.save()
    }
    // Support Function
    private func setLogEntity(from reqLog: ChallengeLog) throws {
        
        // Create LogEntity & Serialize
        let logEntity = ChallengeLogEntity(context: context)
        let log = try NSKeyedArchiver.archivedData(withRootObject: reqLog.log_complete, requiringSecureCoding: false)
        
        logEntity.log_user_id = reqLog.log_user_id
        logEntity.log_complete = log as NSObject
        logEntity.log_update_at = reqLog.log_update_at
    }
    
    //================================
    // MARK: - Get ChallengeLog
    //================================
    func getLog(from identifier: String) throws -> ChallengeLog {
        
        // parameter setting
        let fetchReq: NSFetchRequest<ChallengeLogEntity> = ChallengeLogEntity.fetchRequest()
        
        // Request Query
        fetchReq.predicate = NSPredicate(format: "log_user_id == %@", identifier)
        fetchReq.fetchLimit = 1
        
        // Search Data
        guard let reqLog = try context.fetch(fetchReq).first else {
            throw ChallengeLogErrorCD.ChallengeLogRetrievalByIdentifierFailed
        }
        // Deserialize Data
        guard let logData = reqLog.log_complete as? Data,
              let log = try NSKeyedUnarchiver.unarchivedObject(
                ofClasses: [NSArray.self, NSDictionary.self, NSDate.self], from: logData) as? [[Int: Date]]
        else {
            throw ChallengeLogErrorCD.UnexpectedDeserializeError
        }
        // Convert to Log & Get
        guard let challengeLog = ChallengeLog(from: reqLog, log: log) else {
            throw ChallengeLogErrorCD.UnexpectedConvertError
        }
        return challengeLog
    }
    
    //================================
    // MARK: - Update ChallengeLog
    //================================
    func updateLog(from userId: String, updatedLog: [Int:Date], updatedAt: Date) throws {
        
        // parameter setting
        let fetchReq: NSFetchRequest<ChallengeLogEntity> = ChallengeLogEntity.fetchRequest()
        
        // Request Query
        fetchReq.predicate = NSPredicate(format: "log_user_id == %@", userId)
        fetchReq.fetchLimit = 1
        
        // Search Data
        guard let reqLog = try context.fetch(fetchReq).first else {
            throw ChallengeLogErrorCD.ChallengeLogRetrievalByIdentifierFailed
        }
        // Deserialize Data
        guard let logData = reqLog.log_complete as? Data,
              var log = try NSKeyedUnarchiver.unarchivedObject(
                ofClasses: [NSArray.self, NSDictionary.self, NSDate.self], from: logData) as? [[Int: Date]]
        else {
            throw ChallengeLogErrorCD.UnexpectedDeserializeError
        }
        // Append Data
        log.append(updatedLog)
        
        // Serialize Data
        let updated = try NSKeyedArchiver.archivedData(withRootObject: log, requiringSecureCoding: false)
        
        // Update Data
        reqLog.log_complete = updated as NSObject
        reqLog.log_update_at = updatedAt
        try context.save()
    }
    
    //================================
    // MARK: - Delete ChallengeLog
    //================================
    func deleteLog(from identifier: String) throws {
        
        // parameter setting
        let fetchReq: NSFetchRequest<ChallengeLogEntity> = ChallengeLogEntity.fetchRequest()
        
        // Request Query
        fetchReq.predicate = NSPredicate(format: "log_user_id == %@", identifier)
        fetchReq.fetchLimit = 1
        
        // Search Data
        guard let reqLog = try context.fetch(fetchReq).first else {
            throw ChallengeLogErrorCD.ChallengeLogRetrievalByIdentifierFailed
        }
        // Delete Data
        context.delete(reqLog)
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
