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
    let util = Utilities()
    let cd = CoreDataManager.shared
    var context: NSManagedObjectContext {
        return cd.context
    }
    
    //================================
    // MARK: - Set AccessLog
    //================================
    func setLog(with log: AccessLog) throws {
        
        // Create Entity & Set Data
        try setLogEntity(with: log)
        try context.save()
    }
    // Support Function
    private func setLogEntity(with log: AccessLog) throws {
        // Convert Log to JSON
        let entity = AccessLogEntity(context: context)
        let log_access_string = try util.convertToJSON(data: log.log_access)
        
        entity.log_user_id = log.log_user_id
        entity.log_access = log_access_string
    }
    
    //================================
    // MARK: - Get AccessLog
    //================================
    func getLog(with userId: String) throws -> AccessLog {
        
        // parameter setting
        let fetchReq: NSFetchRequest<AccessLogEntity> = AccessLogEntity.fetchRequest()
        
        // Request Query
        fetchReq.predicate = NSPredicate(format: "log_user_id == %@", userId)
        fetchReq.fetchLimit = 1
        
        // Search Data
        guard let entity = try context.fetch(fetchReq).first else {
            throw AccessLogErrorCD.AccLogRetrievalByIdentifierFailed
        }
        // Convert JSON to Log
        let log = try util.convertFromJSON(jsonString: entity.log_access, type: [Date].self)
        
        return AccessLog(with: userId, and: log)
    }
    
    //================================
    // MARK: - Update AccessLog
    //================================
    func updateLog(with userId: String, when: Date) throws {
        
        // parameter setting
        let fetchReq: NSFetchRequest<AccessLogEntity> = AccessLogEntity.fetchRequest()
        
        // Request Query
        fetchReq.predicate = NSPredicate(format: "log_user_id == %@", userId)
        fetchReq.fetchLimit = 1
        
        // Search Data
        guard let entity = try self.context.fetch(fetchReq).first else {
            throw AccessLogErrorCD.AccLogRetrievalByIdentifierFailed
        }
        // Convert JSON to Log
        var log = try util.convertFromJSON(jsonString: entity.log_access, type: [Date].self)
    
        // Update Data
        log.append(when)
        
        // Convert Log to JSON
        let log_access_string = try util.convertToJSON(data: log)
        entity.log_access = log_access_string
        try context.save()
    }
    
    //================================
    // MARK: - Delete AccessLog
    //================================
    func deleteLog(with userId: String) throws {
        
        // parameter setting
        let fetchReq: NSFetchRequest<AccessLogEntity> = AccessLogEntity.fetchRequest()
        
        // Request Query
        fetchReq.predicate = NSPredicate(format: "log_user_id == %@", userId)
        fetchReq.fetchLimit = 1
        
        // Search Data
        guard let entity = try context.fetch(fetchReq).first else {
            throw AccessLogErrorCD.AccLogRetrievalByIdentifierFailed
        }
        // Delete Log
        context.delete(entity)
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
    
    var errorDescription: String?{
        switch self {
        case .AccLogRetrievalByIdentifierFailed:
            return "Coredata: Unable to retrieve 'AccessLog' data using the provided identifier."
        case .UnexpectedConvertError:
            return "Coredata: There was an unexpected error while Convert 'AccessLog' details"
        case .InternalError:
            return "Coredata: Internal Error Occurred while process 'AccessLog' details"
        }
    }
}
