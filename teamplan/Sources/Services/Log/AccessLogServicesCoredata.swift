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
    // MARK: - CoreData Setting
    //================================
    let cd = CoreDataManager.shared
    var context: NSManagedObjectContext {
        return cd.context
    }
    
    //================================
    // MARK: - Set AccessLog
    //================================
    func setAccessLog(reqLog: AccessLog,
                     result: @escaping(Result<String, Error>) -> Void) {
        
        // Create new LogEntity
        let logEntity = AccessLogEntity(context: context)
        
        // Set AccessLog Info
        logEntity.log_user_id = reqLog.log_user_id
        logEntity.log_access = reqLog.log_access as NSObject
        
        // Set Log
        do {
            try context.save()
            return result(.success("Successfully Set AccessLog"))
        } catch {
            return result(.failure(AccessLogError.UnexpectedSetError))
        }
    }
    
    //================================
    // MARK: - Get AccessLog
    //================================
    func getAccessLog(identifier: String,
                      result: @escaping(Result<AccessLog, Error>) -> Void) {
        
        // parameter setting
        let fetchReq: NSFetchRequest<AccessLogEntity> = AccessLogEntity.fetchRequest()
        
        // Request Query
        fetchReq.predicate = NSPredicate(format: "log_user_id == %@", identifier)
        fetchReq.fetchLimit = 1
        
        do{
            // Exception Handling: Idnetifier
            guard let reqLog = try context.fetch(fetchReq).first else {
                return result(.failure(AccessLogError.AccLogRetrievalByIdentifierFailed))
            }
            
            // Successfully Get AccessLog from Coredata
            return result(.success(AccessLog(acclogEntity: reqLog)))
            
        // Exception Handling: Internal Error (Coredata)
        } catch {
            return result(.failure(AccessLogError.UnexpectedError))
        }
    }
    
    //================================
    // MARK: - Update AccessLog
    //================================
    func updateAccessLog(identifier: String, updatedAcclog: AccessLog,
                         result: @escaping(Result<String, Error>) -> Void) {
        
        // parameter setting
        let fetchReq: NSFetchRequest<AccessLogEntity> = AccessLogEntity.fetchRequest()
        
        // Request Query
        fetchReq.predicate = NSPredicate(format: "log_user_id == %@", identifier)
        fetchReq.fetchLimit = 1
        
        do {
            // Exception Handling: Idnetifier
            guard let acclogEntity = try self.context.fetch(fetchReq).first else {
                return result(.failure(AccessLogError.AccLogRetrievalByIdentifierFailed))
            }
            
            // Update AccessLog
            acclogEntity.log_access = updatedAcclog.log_access as NSObject
            try self.context.save()
            
            result(.success("Successfully Set AccessLog"))
            
        // Eception Handling: Internal Error
        } catch {
            result(.failure(AccessLogError.UnexpectedUpdateError))
        }
    }
}

//===============================
// MARK: - Exception
//===============================
enum AccessLogError: LocalizedError {
    case AccLogRetrievalByIdentifierFailed
    case UnexpectedError
    case UnexpectedSetError
    case UnexpectedGetError
    case UnexpectedUpdateError
    
    var errorDescription: String?{
        switch self {
        case .AccLogRetrievalByIdentifierFailed:
            return "Coredata: Unable to retrieve 'AccessLog' data using the provided identifier."
        case .UnexpectedError:
            return "Coredata: There was an unexpected error about 'AccessLog'"
        case .UnexpectedSetError:
            return "Coredata: There was an unexpected error while Set 'AccessLog' details"
        case .UnexpectedGetError:
            return "Coredata: There was an unexpected error while Get 'AccessLog' details"
        case .UnexpectedUpdateError:
            return "Coredata: There was an unexpected error while Update 'AccessLog' details"
        }
    }
}
