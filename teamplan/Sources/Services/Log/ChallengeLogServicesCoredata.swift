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
extension ChallengeLogServicesCoredata{
    
    //--------------------
    // Set
    //--------------------
    func setLog(with log: ChallengeLog) throws {
        // create & set
        try setEntity(with: log)
        try context.save()
    }
    
    //--------------------
    // Get
    //--------------------
    // Single
    func getLog(with userId: String, and logId: Int) throws -> ChallengeLog {
        // fetch entity
        let entity = try fetchEntity(with: userId, and: logId)
        // convert & return
        return try convertToLog(with: entity)
    }
    // List
    func getLogList(with userId: String) throws -> [ChallengeLog] {
        // fetch entities
        let entities = try fetchEntities(with: userId)
        // convert & return
        return try entities.map { try convertToLog(with: $0) }
    }
    
    //--------------------
    // Update
    //--------------------
    func updateLog(with updated: ChallengeLogUpdateDTO) throws {
        // fetch entity
        let entity = try fetchEntity(with: updated.userId, and: updated.logId)
        // check & update
        if try checkUpdate(from: entity, with: updated) {
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
extension ChallengeLogServicesCoredata{
    
    // Set Entity
    private func setEntity(with log: ChallengeLog) throws {
        let log_complete_string = try util.convertToJSON(data: log.log_complete)
        let entity = ChallengeLogEntity(context: context)
        
        entity.log_id = Int32(log.log_id)
        entity.log_user_id = log.log_user_id
        entity.log_complete = log_complete_string
        entity.log_upload_at = log.log_upload_at
    }
    //----------------------------------------------
    
    // Fetch Entity
    private func fetchEntity(with userId: String, and logId: Int) throws -> ChallengeLogEntity {
        // parameter setting
        let fetchReq: NSFetchRequest<ChallengeLogEntity> = ChallengeLogEntity.fetchRequest()
        // request query
        fetchReq.predicate = NSPredicate(format: "log_user_id == %@ AND log_id == %d", userId, logId)
        fetchReq.fetchLimit = 1
        // convert & return
        guard let entity = try context.fetch(fetchReq).first else {
            throw ChallengeErrorCD.ChallengeRetrievalByIdentifierFailed
        }
        return entity
    }
    
    // Fetch Entities
    private func fetchEntities(with userId: String) throws -> [ChallengeLogEntity] {
        // parameter setting
        let fetchReq: NSFetchRequest<ChallengeLogEntity> = ChallengeLogEntity.fetchRequest()
        // request query
        fetchReq.predicate = NSPredicate(format: "log_user_id == %@", userId)
        // fetch & return
        return try context.fetch(fetchReq)
    }
    //----------------------------------------------
    
    // Convert: to Object
    private func convertToLog(with entity: ChallengeLogEntity) throws -> ChallengeLog {
        // ready element
        guard let logCompleteString = entity.log_complete else {
            throw ChallengeLogErrorCD.UnexpectedFetchError
        }
        // convert element
        let logComplete = try util.convertFromJSON(jsonString: logCompleteString, type: [Int:Date].self)
        // convert & return
        guard let log = ChallengeLog(from: entity, log: logComplete) else {
            throw ChallengeLogErrorCD.UnexpectedConvertError
        }
        return log
    }
    //----------------------------------------------
    
    // Update: Check
    private func checkUpdate(from entity: ChallengeLogEntity, with dto: ChallengeLogUpdateDTO) throws -> Bool {
        var isUpdated = false
        
        if let newLogComplete = try updateLog(with: entity, to: dto) {
            isUpdated = util.updateFieldIfNeeded(&entity.log_complete, newValue: newLogComplete) || isUpdated
        }
        if let newUploadAt = dto.uploadAt {
            isUpdated = util.updateFieldIfNeeded(&entity.log_upload_at, newValue: newUploadAt) || isUpdated
        }
        return isUpdated
    }
    
    // Update: Append Log
    private func updateLog(with entity: ChallengeLogEntity, to updated: ChallengeLogUpdateDTO) throws -> String? {
        // nil check
        guard let challengeId = updated.challengeId,
              let updatedAt = updated.updatedAt else {
            return nil
        }
        // ready parameter
        guard let logCompleteString = entity.log_complete else {
            return nil
        }
        var logComplete = try util.convertFromJSON(jsonString: logCompleteString, type: [Int:Date].self)
        
        // update log
        logComplete[challengeId] = updatedAt
        return try util.convertToJSON(data: logComplete)
    }
}

//===============================
// MARK: - Exception
//===============================
enum ChallengeLogErrorCD: LocalizedError {
    case UnexpectedConvertError
    case UnexpectedFetchError
    case UnexpectedSearchError
    
    var errorDescription: String?{
        switch self {
        case .UnexpectedConvertError:
            return "Coredata: There was an unexpected error while Convert 'ChallengeLog' details"
        case .UnexpectedFetchError:
            return "Coredata: There was an unexpected error while Fetch 'ChallengeLog' details"
        case .UnexpectedSearchError:
            return "CoreData: There was an unexpected error while Search 'ChallengeLog' with Given UserId"
        }
    }
}
