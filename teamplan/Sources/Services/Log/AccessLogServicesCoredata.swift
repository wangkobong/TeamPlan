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
    // MARK: - Parameter
    //================================
    let util = Utilities()
    let cd = CoreDataManager.shared
    var context: NSManagedObjectContext {
        return cd.context
    }
}

//================================
// MARK: - Main Function
//================================
extension AccessLogServicesCoredata{
    
    //--------------------
    // Set
    //--------------------
    func setLog(with log: AccessLog) throws {
        try setEntity(with: log)
        try context.save()
    }
    
    //--------------------
    // Get
    //--------------------
    // Single
    func getLog(with userId: String, and logId: Int) throws -> AccessLog {
        // fetch entity
        let entity = try fetchEntity(with: userId, and: logId)
        // convert & return
        return try convertToLog(with: entity)
    }
    // List
    func getLogList(with userId: String) throws -> [AccessLog] {
        // fetch entities
        let entities = try fetchEntities(with: userId)
        // convert & return
        return try entities.map { try convertToLog(with: $0) }
    }
    
    //--------------------
    // Update
    //--------------------
    func updateLog(with dto: AccessLogUpdateDTO) throws {
        // fetch entity
        let entity = try fetchEntity(with: dto.userId, and: dto.logId)
        // update & apply
        if try checkUpdate(from: entity, with: dto) {
            try context.save()
        }
    }
    
    //--------------------
    // Delete
    //--------------------
    // Single
    func deleteLog(with userId: String, and logId: Int) throws {
        // fetch entity
        let entity = try fetchEntity(with: userId, and: logId)
        // delete & apply
        context.delete(entity)
        try context.save()
    }
    // List
    func deleteLogList(with userId: String) throws {
        // fetch entities
        let entities = try fetchEntities(with: userId)
        // delete & apply
        entities.forEach(context.delete)
        try context.save()
    }
}

//================================
// MARK: - Support Function
//================================
extension AccessLogServicesCoredata{
    
    // Set
    private func setEntity(with log: AccessLog) throws {
        let entity = AccessLogEntity(context: context)
        let log_access_string = try util.convertToJSON(data: log.log_access)
        
        entity.log_id = Int32(log.log_id)
        entity.log_user_id = log.log_user_id
        entity.log_access = log_access_string
        entity.log_upload_at = log.log_upload_at
    }
    //----------------------------------------------
    
    // Fetch
    private func fetchEntity(with userId: String, and logId: Int) throws -> AccessLogEntity {
        // parameter setting
        let fetchReq: NSFetchRequest<AccessLogEntity> = AccessLogEntity.fetchRequest()
        // Request Query
        fetchReq.predicate = NSPredicate(format: "log_user_id == %@ AND log_id = %d", userId, logId)
        fetchReq.fetchLimit = 1
        // Search Data
        guard let entity = try context.fetch(fetchReq).first else {
            throw AccessLogErrorCD.UnexpectedSearchError
        }
        return entity
    }
    
    // Fetch Entities
    private func fetchEntities(with userId: String) throws -> [AccessLogEntity] {
        // parameter setting
        let fetchReq: NSFetchRequest<AccessLogEntity> = AccessLogEntity.fetchRequest()
        // request query
        fetchReq.predicate = NSPredicate(format: "log_user_id == %@", userId)
        // fetch & return
        return try context.fetch(fetchReq)
    }
    //----------------------------------------------
    
    // Convert: to Object
    private func convertToLog(with entity: AccessLogEntity) throws -> AccessLog {
        // ready element
        guard let logAccessString = entity.log_access else {
            throw AccessLogErrorCD.UnexpectedFetchError
        }
        // convert element
        let logAccess = try util.convertFromJSON(jsonString: logAccessString, type: [Date].self)
        // convert & return
        guard let log = AccessLog(with: entity, log: logAccess) else {
            throw AccessLogErrorCD.UnexpectedConvertError
        }
        return log
    }
    //----------------------------------------------
    
    // Update: Check
    private func checkUpdate(from entity: AccessLogEntity, with dto: AccessLogUpdateDTO) throws -> Bool {
        var isUpdated = false
        
        if let newLogAccess = dto.newAccessDate {
            guard let log = try updateLog(with: entity, to: newLogAccess) else {
                throw AccessLogErrorCD.UnexpectedConvertError
            }
            isUpdated = util.updateFieldIfNeeded(&entity.log_access, newValue: log) || isUpdated
        }
        if let newUploadAt = dto.newUploadAt {
            isUpdated = util.updateFieldIfNeeded(&entity.log_upload_at, newValue: newUploadAt) || isUpdated
        }
        return isUpdated
    }
    
    // Update: Append Log
    private func updateLog(with entity: AccessLogEntity, to updated: Date) throws -> String? {
        guard let logAccessString = entity.log_access else {
            throw AccessLogErrorCD.UnexpectedFetchError
        }
        var logAccess = try util.convertFromJSON(jsonString: logAccessString, type: [Date].self)
        logAccess.append(updated)
        return try util.convertToJSON(data: logAccess)
    }
}

//===============================
// MARK: - Exception
//===============================
enum AccessLogErrorCD: LocalizedError {
    case UnexpectedConvertError
    case UnexpectedFetchError
    case UnexpectedSearchError
    
    var errorDescription: String?{
        switch self {
        case .UnexpectedConvertError:
            return "Coredata: There was an unexpected error while Convert 'AccessLog' details"
        case .UnexpectedFetchError:
            return "Coredata: There was an unexpected error while Fetch 'AccessLog' details"
        case .UnexpectedSearchError:
            return "CoreData: There was an unexpected error while Search 'AccessLog' with Given UserId"
        }
    }
}
