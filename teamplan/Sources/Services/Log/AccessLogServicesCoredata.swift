//
//  AccessLogServicesCoredata.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/10/20.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation
import CoreData

final class AccessLogServicesCoredata{
    
    //================================
    // MARK: - Parameter Setting
    //================================
    let cd = CoreDataManager.shared
    var context: NSManagedObjectContext {
        return cd.context
    }
    
    //================================
    // MARK: - Set AccessLog
    //================================
    func setLog(reqLog: AccessLog) throws {
        
        // Create Entity & Set Data
        setLogEntity(from: reqLog)
        try context.save()
    }
    // Support Function
    private func setLogEntity(from reqLog: AccessLog) {
        let logEntity = AccessLogEntity(context: context)
        
        logEntity.log_user_id = reqLog.log_user_id
        logEntity.log_access = reqLog.log_access as NSObject
    }
    
    //================================
    // MARK: - Get AccessLog
    //================================
    func getLog(from userId: String) throws -> AccessLog {
        
        // parameter setting
        let fetchReq: NSFetchRequest<AccessLogEntity> = AccessLogEntity.fetchRequest()
        
        // Request Query
        fetchReq.predicate = NSPredicate(format: "log_user_id == %@", userId)
        fetchReq.fetchLimit = 1
        
        // Search Data
        guard let reqLog = try context.fetch(fetchReq).first else {
            throw AccessLogErrorCD.AccLogRetrievalByIdentifierFailed
        }
        // Convert to Log
        guard let log = AccessLog(logEntity: reqLog) else {
            throw AccessLogErrorCD.UnexpectedConvertError
        }
        return log
    }
    
    //================================
    // MARK: - Update AccessLog
    //================================
    func updateLog(from userId: String, updatedAt: Date) throws {
        
        // parameter setting
        let fetchReq: NSFetchRequest<AccessLogEntity> = AccessLogEntity.fetchRequest()
        
        // Request Query
        fetchReq.predicate = NSPredicate(format: "log_user_id == %@", userId)
        fetchReq.fetchLimit = 1
        
        // Search Data
        guard let reqLog = try self.context.fetch(fetchReq).first else {
            throw AccessLogErrorCD.AccLogRetrievalByIdentifierFailed
        }
        // Convert to Array
        guard var log = reqLog.log_access as? [Date] else {
            throw AccessLogErrorCD.UnexpectedConvertError
        }
        // Update Data
        log.append(updatedAt)
        reqLog.log_access = log as NSObject
        try context.save()
    }
    
    //================================
    // MARK: - Delete AccessLog
    //================================
    func deleteLog(identifier: String) throws {
        
        // parameter setting
        let fetchReq: NSFetchRequest<AccessLogEntity> = AccessLogEntity.fetchRequest()
        
        // Request Query
        fetchReq.predicate = NSPredicate(format: "log_user_id == %@", identifier)
        fetchReq.fetchLimit = 1
        
        // Search Data
        guard let reqLog = try context.fetch(fetchReq).first else {
            throw AccessLogErrorCD.AccLogRetrievalByIdentifierFailed
        }
        // Delete Log
        context.delete(reqLog)
        try context.save()
    }
}

//===============================
// MARK: - Exception
//===============================
enum AccessLogErrorCD: LocalizedError {
    case AccLogRetrievalByIdentifierFailed
    case UnexpectedConvertError
    case InternalError
    // Legacy Only
    case UnexpectedSetError
    case UnexpectedGetError
    case UnexpectedUpdateError
    case UnexpectedDeleteError
    
    var errorDescription: String?{
        switch self {
        case .AccLogRetrievalByIdentifierFailed:
            return "Coredata: Unable to retrieve 'AccessLog' data using the provided identifier."
        case .UnexpectedConvertError:
            return "Coredata: There was an unexpected error while Convert 'AccessLog' details"
        case .InternalError:
            return "Coredata: Internal Error Occurred while process 'AccessLog' details"
        // Legacy Only
        case .UnexpectedSetError:
            return "Coredata: There was an unexpected error while Set 'AccessLog' details"
        case .UnexpectedGetError:
            return "Coredata: There was an unexpected error while Get 'AccessLog' details"
        case .UnexpectedUpdateError:
            return "Coredata: There was an unexpected error while Update 'AccessLog' details"
        case .UnexpectedDeleteError:
            return "Coredata: There was an unexpected error while Delete 'AccessLog' details"
        }
    }
}
