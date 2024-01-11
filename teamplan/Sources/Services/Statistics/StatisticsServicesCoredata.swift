//
//  StatisticsServiceCoredata.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/10/10.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation
import CoreData

final class StatisticsServicesCoredata{
    
    //================================
    // MARK: - Parameter
    //================================
    let util = Utilities()
    let cm = CoreDataManager.shared
    var context: NSManagedObjectContext {
        return cm.context
    }
}

//================================
// MARK: - Main Function
//================================
extension StatisticsServicesCoredata{
    
    //--------------------
    // Set
    //--------------------
    func setStatistics(with object: StatisticsObject) throws {
        // Create Entity
        try createStatEntity(with: object)
        // Set Entity
        try context.save()
    }
    
    //--------------------
    // Get
    //--------------------
    // Object
    func getStatisticsForObject(with userId: String) throws -> StatisticsObject {
        // Fetch Data
        let entity = try fetchEntity(with: userId)
        let data = try convertToData(with: entity)
        // Convert & Return
        return try convertToObject(
            entity: entity, challengeStep: data.chlgStep, myChallenge: data.myChlg, logHead: data.logHead
        )
    }
    
    // DTO
    func getStatisticsForDTO(with userId: String, type: DTOType) throws -> Any {
        // Fetch Data
        let entity = try fetchEntity(with: userId)
        let data = try convertToData(with: entity)
        // Convert & Return
        return try convertToDTO(entity: entity, userId: userId, challengeStep: data.chlgStep, myChallenge: data.myChlg, type: type)
    }
    
    //--------------------
    // Update
    //--------------------
    func updateStatistics(with dto: StatUpdateDTO) throws {
        // Fetch Entity
        let entity = try fetchEntity(with: dto.userId)
        // Update Data
        if try checkUpdate(with: entity, to: dto) {
            try context.save()
        }
    }

    //--------------------
    // Delete
    //--------------------
    func deleteStatistics(with userId: String) throws {
        // Fetch Entity
        let entity = try fetchEntity(with: userId)
        // Delete Data
        context.delete(entity)
        try context.save()
    }
}

//================================
// MARK: - Support Function
//================================
extension StatisticsServicesCoredata{

    // Set Entity
    private func createStatEntity(with object: StatisticsObject) throws {
        // Convert Element
        let challengeStepString = try util.convertToJSON(data: object.stat_chlg_step)
        let myChallengeString = try util.convertToJSON(data: object.stat_mychlg)
        let logHeadString = try util.convertToJSON(data: object.stat_log_head)
        
        // Create Entity
        let entity = StatisticsEntity(context: context)
        entity.stat_user_id = object.stat_user_id
        entity.stat_term = Int32(object.stat_term)
        entity.stat_drop = Int32(object.stat_drop)
        entity.stat_proj_reg = Int32(object.stat_proj_reg)
        entity.stat_proj_fin = Int32(object.stat_proj_fin)
        entity.stat_proj_alert = Int32(object.stat_proj_alert)
        entity.stat_proj_ext = Int32(object.stat_proj_ext)
        entity.stat_todo_reg = Int32(object.stat_todo_reg)
        entity.stat_chlg_step = challengeStepString
        entity.stat_mychlg = myChallengeString
        entity.stat_log_head = logHeadString
        entity.stat_upload_at = object.stat_upload_at
    }
    //----------------------------------------------
    
    // Fetch Entity
    private func fetchEntity(with userId: String) throws -> StatisticsEntity {
        // parameter setting
        let fetchReq: NSFetchRequest<StatisticsEntity> = StatisticsEntity.fetchRequest()
        
        // Request Query
        fetchReq.predicate = NSPredicate(format: "stat_user_id == %@", userId)
        fetchReq.fetchLimit = 1
        
        // Search Data
        guard let entity = try context.fetch(fetchReq).first else {
            throw StatErrorCD.UnexpectedSearchError
        }
        return entity
    }
    //----------------------------------------------
    
    // Convert: to Data
    private func convertToData(with entity: StatisticsEntity) throws ->
        (chlgStep: [Int:Int], myChlg: [Int], logHead: [Int:Int]) {
        // Fetch JSON from Entity
        guard let challengeStepString = entity.stat_chlg_step,
              let myChallengeString = entity.stat_mychlg,
              let logHeadString = entity.stat_log_head
        else {
            throw StatErrorCD.UnexpectedConvertError
        }
        // Convert JSON to Array & return
        return (
            chlgStep: try util.convertFromJSON(jsonString: challengeStepString, type: [Int : Int].self),
            myChlg: try util.convertFromJSON(jsonString: myChallengeString, type: [Int].self),
            logHead: try util.convertFromJSON(jsonString: logHeadString, type: [Int:Int].self)
        )
    }
    // Convert: to Object
    private func convertToObject(entity: StatisticsEntity,
                                 challengeStep: [Int:Int], myChallenge: [Int], logHead: [Int:Int]) throws -> StatisticsObject {
        guard let object = StatisticsObject(entity: entity, challengeStep: challengeStep, myChallenge: myChallenge, logHead: logHead)
        else {
            throw StatErrorCD.UnexpectedConvertError
        }
        return object
    }
    // Convert: to DTO
    private func convertToDTO(
        entity: StatisticsEntity, userId: String, challengeStep: [Int:Int], myChallenge: [Int], type: DTOType) throws -> Any {
        switch type {
        case .login:
            return StatLoginDTO(with: userId, entity: entity)
        case .home:
            return StatHomeDTO(with: userId, entity: entity)
        case .project:
            return StatProjectDTO(with: userId, entity: entity)
        case .todo:
            return StatTodoDTO(with: userId, entity: entity)
        case .challenge:
            return StatChallengeDTO(
                with: userId, entity: entity, chlgStep: challengeStep, mychlg: myChallenge)
        case .center:
            return StatCenterDTO(
                with: userId, entity: entity, chlgStep: challengeStep, mychlg: myChallenge)
        }
    }
    //----------------------------------------------
    
    // Update Check
    private func checkUpdate(with entity: StatisticsEntity, to dto: StatUpdateDTO) throws -> Bool {
        var isUpdated = false
        
        if let newDrop = dto.newDrop {
            isUpdated = util.updateFieldIfNeeded(&entity.stat_drop, newValue: Int32(newDrop)) || isUpdated
        }
        if let newTerm = dto.newTerm {
            isUpdated = util.updateFieldIfNeeded(&entity.stat_term, newValue: Int32(newTerm)) || isUpdated
        }
        if let newProjectRegisted = dto.newProjectRegisted {
            isUpdated = util.updateFieldIfNeeded(&entity.stat_proj_reg, newValue: Int32(newProjectRegisted)) || isUpdated
        }
        if let newProjectFinished = dto.newProjectFinished {
            isUpdated = util.updateFieldIfNeeded(&entity.stat_proj_fin, newValue: Int32(newProjectFinished)) || isUpdated
        }
        if let newProjectAlerted = dto.newProjectAlerted {
            isUpdated = util.updateFieldIfNeeded(&entity.stat_proj_alert, newValue: Int32(newProjectAlerted)) || isUpdated
        }
        if let newProjectExtended = dto.newProjectExtended {
            isUpdated = util.updateFieldIfNeeded(&entity.stat_proj_ext, newValue: Int32(newProjectExtended)) || isUpdated
        }
        if let newTodoRegisted = dto.newTodoRegisted {
            isUpdated = util.updateFieldIfNeeded(&entity.stat_todo_reg, newValue: Int32(newTodoRegisted)) || isUpdated
        }
        if let newTodoLimit = dto.newTodoLimit {
            isUpdated = util.updateFieldIfNeeded(&entity.stat_todo_limit, newValue: Int32(newTodoLimit)) || isUpdated
        }
        if let newUploadAt = dto.newUploadAt {
            isUpdated = util.updateFieldIfNeeded(&entity.stat_upload_at, newValue: newUploadAt)
        }
        if let newLogHead = dto.newLogHead {
            let newLogHeadString = try util.convertToJSON(data: newLogHead)
            isUpdated = util.updateFieldIfNeeded(&entity.stat_log_head, newValue: newLogHeadString) || isUpdated
        }
        if let newChallengeStep = dto.newChallengeStep {
            let newChallengeStepString = try util.convertToJSON(data: newChallengeStep)
            isUpdated = util.updateFieldIfNeeded(&entity.stat_chlg_step, newValue: newChallengeStepString) || isUpdated
        }
        if let newMyChallenge = dto.newMyChallenge {
            let newMyChallengeString = try util.convertToJSON(data: newMyChallenge)
            isUpdated = util.updateFieldIfNeeded(&entity.stat_mychlg, newValue: newMyChallengeString) || isUpdated
        }
        return isUpdated
    }
}

//===============================
// MARK: - Exception
//===============================
enum StatErrorCD: LocalizedError {
    case UnexpectedSearchError
    case UnexpectedConvertError
    case UnexpectedFetchError
    
    var errorDescription: String?{
        switch self {
        case .UnexpectedSearchError:
            return "Coredata: There was an unexpected error while Search 'Statistics' with Given 'UserId'"
        case .UnexpectedConvertError:
            return "Coredata: There was an unexpected error while Convert 'Statistics' details"
        case .UnexpectedFetchError:
            return "Coredata: There was an unexpected error while Fetch 'Statistics' details"
        }
    }
}
