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

//===============================
// MARK: - Legacy
//===============================
extension AccessLogServicesCoredata{
    // Set Log
    func setAccessLog(reqLog: AccessLog,
                     result: @escaping(Result<String, Error>) -> Void) {
        do {
            setLogEntity(from: reqLog)
            try context.save()
            return result(.success("Successfully Set AccessLog"))
        } catch {
            print("(CoreData) Error Set AccessLog : \(error)")
            return result(.failure(AccessLogErrorCD.UnexpectedSetError))
        }
    }
    
    // Get Log
    func getAccessLog(identifier: String,
                      result: @escaping(Result<AccessLog, Error>) -> Void) {
        
        let fetchReq: NSFetchRequest<AccessLogEntity> = AccessLogEntity.fetchRequest()
        fetchReq.predicate = NSPredicate(format: "log_user_id == %@", identifier)
        fetchReq.fetchLimit = 1
        
        do{
            guard let reqLog = try context.fetch(fetchReq).first else {
                return result(.failure(AccessLogErrorCD.AccLogRetrievalByIdentifierFailed))
            }
            guard let log = AccessLog(logEntity: reqLog) else {
                return result(.failure(AccessLogErrorCD.UnexpectedConvertError))
            }
            return result(.success(log))
        } catch {
            print("(CoreData) Error Get AccessLog : \(error)")
            return result(.failure(AccessLogErrorCD.InternalError))
        }
    }
    
    // Update Log
    func updateAccessLog(identifier: String, updatedAcclog: AccessLog,
                         result: @escaping(Result<String, Error>) -> Void) {
        
        let fetchReq: NSFetchRequest<AccessLogEntity> = AccessLogEntity.fetchRequest()
        fetchReq.predicate = NSPredicate(format: "log_user_id == %@", identifier)
        fetchReq.fetchLimit = 1
        
        do {
            guard let reqLog = try self.context.fetch(fetchReq).first else {
                return result(.failure(AccessLogErrorCD.AccLogRetrievalByIdentifierFailed))
            }
            reqLog.log_access = updatedAcclog.log_access as NSObject
            try self.context.save()
            
            result(.success("Successfully Set AccessLog"))
        } catch {
            print("(CoreData) Error Update AccessLog : \(error)")
            return result(.failure(AccessLogErrorCD.UnexpectedUpdateError))
        }
    }
}
