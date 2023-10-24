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
            return result(.failure(AccessLogError.UpdateFailed))
        }
    }
    
    
    //================================
    // MARK: - Update AccessLog
    //================================
    func updateAccessLog(identifier: String, serviceTerm: Int, loginDate: Date,
                           result: @escaping(Result<String, Error>) -> Void) {
        
        // parameter setting
        let fetchReq: NSFetchRequest<AccessLogEntity> = AccessLogEntity.fetchRequest()
        
        // Request Query
        fetchReq.predicate = NSPredicate(format: "log_user_id == %@", identifier)
        fetchReq.fetchLimit = 1
        
        do{
            let fetchedLog = try context.fetch(fetchReq)
            
            // Exception Handling: Idnetifier
            guard let reqLog = fetchedLog.first else {
                return result(.failure(AccessLogError.IdentifierFetchFailed))
            }
            
            // extract LoginLog Info
            var accessLog = reqLog.log_access as! [Date]
            
            // Service Term Exceeded Check
            if serviceTerm > 365 {
                // Reset LoginLog
                accessLog.removeAll()
            }
            
            // Add LoginLog
            accessLog.append(loginDate)
            reqLog.log_access = accessLog as NSObject
            
            // Update Log
            do{
                try context.save()
                return result(.success("Successfully Update AccessLog"))
            } catch {
                return result(.failure(AccessLogError.UpdateFailed))
            }
        } catch {
            return result(.failure(AccessLogError.UnknownFetchFailed))
        }
    }
    
    //===============================
    // MARK: - Exception
    //===============================
    enum AccessLogError: LocalizedError {
        case UnknownFetchFailed
        case IdentifierFetchFailed
        case SetFailed
        case UpdateFailed
        
        var errorDescription: String? {
            switch self {
            case .UnknownFetchFailed:
                return "Failed to Fetch AccessLog by Unknown Reason"
            case .IdentifierFetchFailed:
                return "Failed to Fetch AccessLog by identifier"
            case .SetFailed:
                return "Failed to Set AccessLog at Coredata"
            case .UpdateFailed:
                return "Failed to Update AccessLog at Coredata"
            }
        }
    }
}
