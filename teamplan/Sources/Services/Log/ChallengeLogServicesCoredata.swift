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
    func setLog(from reqLog: ChallengeLog) async throws {
        do {
            // Set Log
            try setLogEntity(from: reqLog)
            
            // Store Log
            try context.save()
        } catch {
            print("(CoreData) Error Set ChallengeLog : \(error)")
            throw ChallengeLogErrorCD.UnexpectedSetError
        }
    }
    
    //##### Core Function #####
    private func setLogEntity(from reqLog: ChallengeLog) throws {
        
        // Create new LogEntity
        let logEntity = ChallengeLogEntity(context: context)
        
        do {
            // Serialize Log
            let log = try NSKeyedArchiver.archivedData(withRootObject: reqLog.log_complete, requiringSecureCoding: false)
            
            // Set ChallengeLog Info
            logEntity.log_user_id = reqLog.log_user_id
            logEntity.log_complete = log as NSObject
            logEntity.log_update_at = reqLog.log_update_at
        } catch {
            print("(CoreData) Error Serialize ChallengeLog : \(error)")
            throw ChallengeLogErrorCD.UnexpectedSerializeError
        }
    }
    
    //================================
    // MARK: - Get ChallengeLog
    //================================
    func getLog(from identifier: String) async throws -> ChallengeLog {
        
        // parameter setting
        let fetchReq: NSFetchRequest<ChallengeLogEntity> = ChallengeLogEntity.fetchRequest()
        
        // Request Query
        fetchReq.predicate = NSPredicate(format: "log_user_id == %@", identifier)
        fetchReq.fetchLimit = 1
        
        do {
            guard let reqLog = try context.fetch(fetchReq).first else {
                // Exception Handling: Idnetifier
                throw ChallengeLogErrorCD.ChallengeLogRetrievalByIdentifierFailed
            }
            
            // Deserialize Log
            guard let logData = reqLog.log_complete as? Data,
                  let log = try NSKeyedUnarchiver.unarchivedObject(ofClasses: [NSArray.self, NSDictionary.self, NSDate.self], from: logData)
                  as? [[Int: Date]]
            else {
                throw ChallengeLogErrorCD.UnexpectedDeserializeError
            }
            
            // Struct LogData
            guard let chlgLog = ChallengeLog(from: reqLog, log: log) else {
                // Exception Handling: Convert
                throw ChallengeLogErrorCD.UnexpectedConvertError
            }
            return chlgLog
            
        } catch {
            print("(CoreData) Error Get ChallengeLog : \(error)")
            throw ChallengeLogErrorCD.UnexpectedGetError
        }
    }
    
    //================================
    // MARK: - Update ChallengeLog
    //================================
    func updateLog(to id: String, what log: [Int:Date], when updatedAt: Date) async throws {
        try await updateProcess(userId: id, newLog: log, newUpdateAt: updatedAt)
    }

    //##### Core Function #####
    private func updateProcess(userId: String, newLog: [Int: Date], newUpdateAt: Date) async throws {
        // parameter setting
        let fetchReq: NSFetchRequest<ChallengeLogEntity> = ChallengeLogEntity.fetchRequest()
        
        // Request Query
        fetchReq.predicate = NSPredicate(format: "log_user_id == %@", userId)
        fetchReq.fetchLimit = 1
        
        // Search Entity
        guard let reqLog = try context.fetch(fetchReq).first else {
            // Exception Handling: Idnetifier
            throw ChallengeLogErrorCD.ChallengeLogRetrievalByIdentifierFailed
        }
        
        // Update Entity
        if let logCompleteEntity = reqLog.log_complete as? Data,
           
            // 1. Deserialize log
           var logComplete = try NSKeyedUnarchiver.unarchivedObject(ofClasses: [NSArray.self, NSDictionary.self, NSDate.self], from: logCompleteEntity)
            as? [[Int: Date]] {
            
            // 2. Append log
            logComplete.append(newLog)
            
            // 3. Back to Serialize
            let updatedLog = try NSKeyedArchiver.archivedData(withRootObject: logComplete, requiringSecureCoding: false)
            reqLog.log_complete = updatedLog as NSObject
        }
        reqLog.log_update_at = newUpdateAt
        
        try context.save()
    }
    
    //================================
    // MARK: - Delete ChallengeLog
    //================================
    func deleteLog(from identifier: String) async throws {
        do {
            // parameter setting
            let fetchReq: NSFetchRequest<ChallengeLogEntity> = ChallengeLogEntity.fetchRequest()
            
            // Request Query
            fetchReq.predicate = NSPredicate(format: "log_user_id == %@", identifier)
            fetchReq.fetchLimit = 1
            
            guard let reqLog = try context.fetch(fetchReq).first else {
                // Exception Handling: Idnetifier
                throw ChallengeLogErrorCD.ChallengeLogRetrievalByIdentifierFailed
            }
            
            // Delete Log
            context.delete(reqLog)
            try context.save()
            
        } catch {
            print("(CoreData) Error Delete ChallengeLog : \(error)")
            throw ChallengeLogErrorCD.UnexpectedDeleteError
        }
    }
}

//===============================
// MARK: - Exception
//===============================
enum ChallengeLogErrorCD: LocalizedError {
    case UnexpectedSetError
    case UnexpectedSerializeError
    case UnexpectedGetError
    case UnexpectedDeserializeError
    case UnexpectedUpdateError
    case UnexpectedDeleteError
    case UnexpectedConvertError
    case ChallengeLogRetrievalByIdentifierFailed
    
    var errorDescription: String?{
        switch self {
        case .ChallengeLogRetrievalByIdentifierFailed:
            return "CoreData: Unable to retrieve 'ChallengeLog' data using the provided identifier."
        case .UnexpectedSetError:
            return "Coredata: There was an unexpected error while Set 'ChallengeLog' details"
        case .UnexpectedSerializeError:
            return "Coredata: There was an unexpected error while Serialize 'ChallengeLog' details"
        case .UnexpectedGetError:
            return "Coredata: There was an unexpected error while Get 'ChallengeLog' details"
        case .UnexpectedDeserializeError:
            return "Coredata: There was an unexpected error while Deserialize 'ChallengeLog' details"
        case .UnexpectedUpdateError:
            return "Coredata: There was an unexpected error while Update 'ChallengeLog' details"
        case .UnexpectedDeleteError:
            return "Coredata: There was an unexpected error while Delete 'ChallengeLog' details"
        case .UnexpectedConvertError:
            return "Coredata: There was an unexpected error while Convert 'ChallengeLog' details"
        }
    }
}
