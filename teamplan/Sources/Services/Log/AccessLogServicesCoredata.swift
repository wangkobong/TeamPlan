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
    //##### Async/Await #####
    func setAccessLog(reqLog: AccessLog) async throws {
        do{
            // Set Log
            setLogEntity(from: reqLog)
            
            // Store Log
            try context.save()
        } catch {
            print("(CoreData) Error Set AccessLog : \(error)")
            throw AccessLogErrorCD.UnexpectedSetError
        }
    }
    
    //##### Result #####
    func setAccessLog(reqLog: AccessLog,
                     result: @escaping(Result<String, Error>) -> Void) {
        do {
            // Set Log
            setLogEntity(from: reqLog)
            
            // Store Log
            try context.save()
            return result(.success("Successfully Set AccessLog"))
        } catch {
            print("(CoreData) Error Set AccessLog : \(error)")
            return result(.failure(AccessLogErrorCD.UnexpectedSetError))
        }
    }
    
    // Core Function
    private func setLogEntity(from reqLog: AccessLog) {
        // Create new LogEntity
        let logEntity = AccessLogEntity(context: context)
        
        // Set AccessLog Info
        logEntity.log_user_id = reqLog.log_user_id
        logEntity.log_access = reqLog.log_access as NSObject
    }
    
    //================================
    // MARK: - Get AccessLog
    //================================
    //##### Result #####
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
                return result(.failure(AccessLogErrorCD.AccLogRetrievalByIdentifierFailed))
            }
            
            // Successfully Get AccessLog from Coredata
            return result(.success(AccessLog(logEntity: reqLog)))
            
        // Exception Handling: Internal Error (Coredata)
        } catch {
            print("(CoreData) Error Get AccessLog : \(error)")
            return result(.failure(AccessLogErrorCD.InternalError))
        }
    }
    
    //================================
    // MARK: - Update AccessLog
    //================================
    //##### Result #####
    func updateAccessLog(identifier: String, updatedAcclog: AccessLog,
                         result: @escaping(Result<String, Error>) -> Void) {
        
        // parameter setting
        let fetchReq: NSFetchRequest<AccessLogEntity> = AccessLogEntity.fetchRequest()
        
        // Request Query
        fetchReq.predicate = NSPredicate(format: "log_user_id == %@", identifier)
        fetchReq.fetchLimit = 1
        
        do {
            // Exception Handling: Idnetifier
            guard let reqLog = try self.context.fetch(fetchReq).first else {
                return result(.failure(AccessLogErrorCD.AccLogRetrievalByIdentifierFailed))
            }
            
            // Update AccessLog
            reqLog.log_access = updatedAcclog.log_access as NSObject
            try self.context.save()
            
            result(.success("Successfully Set AccessLog"))
            
        // Eception Handling: Internal Error
        } catch {
            print("(CoreData) Error Update AccessLog : \(error)")
            return result(.failure(AccessLogErrorCD.UnexpectedUpdateError))
        }
    }
    
    //================================
    // MARK: - Delete AccessLog
    //================================
    //##### Async/Await #####
    func deleteAccessLog(identifier: String) async throws {
        do {
            // parameter setting
            let fetchReq: NSFetchRequest<AccessLogEntity> = AccessLogEntity.fetchRequest()
            
            // Request Query
            fetchReq.predicate = NSPredicate(format: "log_user_id == %@", identifier)
            fetchReq.fetchLimit = 1
            
            guard let reqLog = try context.fetch(fetchReq).first else {
                // Exception Handling: Identifier
                throw AccessLogErrorCD.AccLogRetrievalByIdentifierFailed
            }
            // Delete Log
            self.context.delete(reqLog)
            try self.context.save()
            
        } catch {
            print("(CoreData) Error Delete AccessLog : \(error)")
            throw AccessLogErrorCD.UnexpectedDeleteError
        }
    }
}

//===============================
// MARK: - Exception
//===============================
enum AccessLogErrorCD: LocalizedError {
    case UnexpectedSetError
    case UnexpectedGetError
    case UnexpectedUpdateError
    case UnexpectedDeleteError
    case AccLogRetrievalByIdentifierFailed
    case InternalError
    
    var errorDescription: String?{
        switch self {
        case .UnexpectedSetError:
            return "Coredata: There was an unexpected error while Set 'AccessLog' details"
        case .UnexpectedGetError:
            return "Coredata: There was an unexpected error while Get 'AccessLog' details"
        case .UnexpectedUpdateError:
            return "Coredata: There was an unexpected error while Update 'AccessLog' details"
        case .UnexpectedDeleteError:
            return "Coredata: There was an unexpected error while Delete 'AccessLog' details"
        case .AccLogRetrievalByIdentifierFailed:
            return "Coredata: Unable to retrieve 'AccessLog' data using the provided identifier."
        case .InternalError:
            return "Coredata: Internal Error Occurred while process 'AccessLog' details"
        }
    }
}
