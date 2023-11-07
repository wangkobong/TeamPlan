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
    //##### Async/Await #####
    func setChallengeLog(reqLog: ChallengeLog) async throws {
        do {
            // Set Log
            setLogEntity(from: reqLog)
            
            // Store Log
            try context.save()
        } catch {
            print("(CoreData) Error Set ChallengeLog : \(error)")
            throw ChallengeLogErrorCD.UnexpectedSetError
        }
    }
    
    //##### Result #####
    func setChallengeLog(reqLog: ChallengeLog,
                         result: @escaping(Result<String, Error>) -> Void) {
        do {
            // Set Log
            setLogEntity(from: reqLog)
            
            // Store Log
            try context.save()
            return result(.success("Successfully Set ChallengeLog"))
        } catch {
            print("(CoreData) Error Set ChallengeLog : \(error)")
            return result(.failure(ChallengeLogErrorCD.UnexpectedSetError))
        }
    }
    
    // Core Function
    private func setLogEntity(from reqLog: ChallengeLog) {
        
        // Create new LogEntity
        let logEntity = ChallengeLogEntity(context: context)
        
        // Set ChallengeLog Info
        logEntity.log_user_id = reqLog.log_user_id
        logEntity.log_complete = reqLog.log_complete as NSObject
        logEntity.log_update_at = reqLog.log_update_at
    }
    
    //================================
    // MARK: - Get ChallengeLog
    //================================
    //##### Async/Await #####
    func getChallengeLog(identifier: String) async throws -> ChallengeLog {
        
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
            
            // Get ChallengeLog from Coredata
            guard let chlgLog = ChallengeLog(logEntity: reqLog) else {
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
    //##### Result #####
    func updateChallengeLog(identifier: String, updatedLog: ChallengeLog,
                            result: @escaping(Result<String, Error>) -> Void) {
        
        // parameter setting
        let fetchReq: NSFetchRequest<ChallengeLogEntity> = ChallengeLogEntity.fetchRequest()
        
        // Request Query
        fetchReq.predicate = NSPredicate(format: "log_user_id == %@", identifier)
        fetchReq.fetchLimit = 1
        
        do {
            guard let reqLog = try context.fetch(fetchReq).first else {
                // Exception Handling: Idnetifier
                return result(.failure(ChallengeLogErrorCD.ChallengeLogRetrievalByIdentifierFailed))
            }
            
            // Update AccessLog
            reqLog.log_complete = updatedLog.log_complete as NSObject
            try context.save()
            
        } catch {
            print("(CoreData) Error Update ChallengeLog : \(error)")
            return result(.failure(ChallengeLogErrorCD.UnexpectedUpdateError))
        }
    }
    
    //================================
    // MARK: - Delete ChallengeLog
    //================================
    //##### Async/Await #####
    func deleteChallengeLog(identifier: String) async throws {
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
    case UnexpectedGetError
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
        case .UnexpectedGetError:
            return "Coredata: There was an unexpected error while Get 'ChallengeLog' details"
        case .UnexpectedUpdateError:
            return "Coredata: There was an unexpected error while Update 'ChallengeLog' details"
        case .UnexpectedDeleteError:
            return "Coredata: There was an unexpected error while Delete 'ChallengeLog' details"
        case .UnexpectedConvertError:
            return "Coredata: There was an unexpected error while Convert 'ChallengeLog' details"
        }
    }
}
