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
    // MARK: - Parameter Setting
    //================================
    let util = Utilities()
    let cd = CoreDataManager.shared
    var context: NSManagedObjectContext {
        return cd.context
    }
    
    //================================
    // MARK: - Set Statistics
    //================================
    func setStatistics(with object: StatisticsObject) throws {
        
        // Create Entity & Set Data
        try setStatEntity(with: object)
        try context.save()
    }
    // Support Function
    private func setStatEntity(with reqStat: StatisticsObject) throws {
        
        // Prepare Entity Create
        let json_stat_chlg_step = try util.convertToJSON(data: reqStat.stat_chlg_step)
        let json_stat_mychlg = try util.convertToJSON(data: reqStat.stat_mychlg)
        let statEntity = StatisticsEntity(context: context)
        
        statEntity.stat_user_id = reqStat.stat_user_id
        statEntity.stat_term = Int32(reqStat.stat_term)
        statEntity.stat_drop = Int32(reqStat.stat_drop)
        statEntity.stat_proj_reg = Int32(reqStat.stat_proj_reg)
        statEntity.stat_proj_fin = Int32(reqStat.stat_proj_fin)
        statEntity.stat_proj_alert = Int32(reqStat.stat_proj_alert)
        statEntity.stat_proj_ext = Int32(reqStat.stat_proj_ext)
        statEntity.stat_todo_reg = Int32(reqStat.stat_todo_reg)
        statEntity.stat_chlg_step = json_stat_chlg_step
        statEntity.stat_mychlg = json_stat_mychlg
        statEntity.stat_upload_at = reqStat.stat_upload_at
    }
    
    //================================
    // MARK: - Get Statistics
    //================================
    
    //--------------------
    // Object
    //--------------------
    func getStatisticsForObject(with userId: String) throws -> StatisticsObject {
        
        // Fetch Data
        let entity = try fetchEntity(with: userId)
        let data = try convertToData(with: entity)
        
        // Convert To Object & Return
        guard let stat = StatisticsObject(statEntity: entity, chlgStep: data.chlgStep, mychlg: data.myChlg)
        else {
            throw StaticErrorCD.UnexpectedConvertError
        }
        return stat
    }
    
    //--------------------
    // DTO
    //--------------------
    func getStatisticsForDTO(with userId: String, type: DTOType) throws -> Any {
        
        // Fetch Data
        let entity = try fetchEntity(with: userId)
        let data = try convertToData(with: entity)
        
        // Convert to DTO & Return
        switch type {
        case .login:
            return StatLoginDTO(with: userId, entity: entity)
        case .project:
            return StatProjectDTO(with: userId, entity: entity)
        case .challenge, .center:
            return type == .challenge ?
                StatChallengeDTO(with: userId, entity: entity, chlgStep: data.chlgStep, mychlg: data.myChlg) :
                StatCenterDTO(with: userId, entity: entity, chlgStep: data.chlgStep, mychlg: data.myChlg)
        }
    }
    
    //--------------------
    // Legacy
    //--------------------
    func getStatistics(from userId: String) throws -> StatisticsObject {
        
        // parameter setting
        let fetchReq: NSFetchRequest<StatisticsEntity> = StatisticsEntity.fetchRequest()
        
        // Request Query
        fetchReq.predicate = NSPredicate(format: "stat_user_id == %@", userId)
        fetchReq.fetchLimit = 1
        
        // Search Data
        guard let reqStat = try context.fetch(fetchReq).first else {
            throw StaticErrorCD.StatRetrievalByIdentifierFailed
        }
        // Convert to Object & Get
        let statData = try convertToObject(reqStat: reqStat)
        return statData
    }
    // Support Function
    private func convertToObject(reqStat: StatisticsEntity) throws -> StatisticsObject {
        
        // Convert JSON to Array
        let chlgStep = try util.convertFromJSON(jsonString: reqStat.stat_chlg_step, type: [Int : Int].self)
        let myChlg = try util.convertFromJSON(jsonString: reqStat.stat_mychlg, type: [Int].self)
        
        // Create Object
        guard let stat = StatisticsObject(statEntity: reqStat, chlgStep: chlgStep, mychlg: myChlg) else {
            throw StaticErrorCD.UnexpectedConvertError
        }
        return stat
    }
    
    //================================
    // MARK: - Update Statistics
    //================================
    func updateStatistics(with dto: StatUpdateDTO) throws {
        
        // Fetch Entity
        let entity = try fetchEntity(with: dto.stat_user_id)
        
        // Update Data
        if try update(with: entity, to: dto) {
            try context.save()
        }
    }
    // Support Function
    private func update(with entity: StatisticsEntity, to dto: StatUpdateDTO) throws -> Bool {
        var isUpdated = false
        
        if let statDrop = dto.stat_drop {
            isUpdated = util.updateFieldIfNeeded(&entity.stat_drop, newValue: Int32(statDrop)) || isUpdated
        }
        if let statTerm = dto.stat_term {
            isUpdated = util.updateFieldIfNeeded(&entity.stat_term, newValue: Int32(statTerm)) || isUpdated
        }
        if let statProjReg = dto.stat_proj_reg {
            isUpdated = util.updateFieldIfNeeded(&entity.stat_proj_reg, newValue: Int32(statProjReg)) || isUpdated
        }
        if let statProjFin = dto.stat_proj_fin {
            isUpdated = util.updateFieldIfNeeded(&entity.stat_proj_fin, newValue: Int32(statProjFin)) || isUpdated
        }
        if let statProjAlert = dto.stat_proj_alert {
            isUpdated = util.updateFieldIfNeeded(&entity.stat_proj_alert, newValue: Int32(statProjAlert)) || isUpdated
        }
        if let statProjExt = dto.stat_proj_ext {
            isUpdated = util.updateFieldIfNeeded(&entity.stat_proj_ext, newValue: Int32(statProjExt)) || isUpdated
        }
        if let statTodoReg = dto.stat_todo_reg {
            isUpdated = util.updateFieldIfNeeded(&entity.stat_todo_reg, newValue: Int32(statTodoReg)) || isUpdated
        }
        if let statChlgStep = dto.stat_chlg_step {
            let chlgStepJSON = try util.convertToJSON(data: statChlgStep)
            isUpdated = util.updateFieldIfNeeded(&entity.stat_chlg_step, newValue: chlgStepJSON) || isUpdated
        }
        if let statMychlg = dto.stat_mychlg {
            let myChlgJSON = try util.convertToJSON(data: statMychlg)
            isUpdated = util.updateFieldIfNeeded(&entity.stat_mychlg, newValue: myChlgJSON) || isUpdated
        }
        return isUpdated
    }

    //================================
    // MARK: - Delete Statistics
    //================================
    func deleteStatistics(with userId: String) throws {
        
        // Fetch Entity
        let entity = try fetchEntity(with: userId)
        
        // Delete Data
        context.delete(entity)
        try context.save()
    }
    
    //================================
    // MARK: - Support Function
    //================================
    // Entity
    private func fetchEntity(with userId: String) throws -> StatisticsEntity {
        // parameter setting
        let fetchReq: NSFetchRequest<StatisticsEntity> = StatisticsEntity.fetchRequest()
        
        // Request Query
        fetchReq.predicate = NSPredicate(format: "stat_user_id == %@", userId)
        fetchReq.fetchLimit = 1
        
        // Search Data
        guard let entity = try context.fetch(fetchReq).first else {
            throw StaticErrorCD.StatRetrievalByIdentifierFailed
        }
        return entity
    }
    
    // Converter
    private func convertToData(with entity: StatisticsEntity) throws -> (chlgStep: [Int: Int], myChlg: [Int]) {
        // Fetch JSON from Entity
        guard let stat_chlg_step_json = entity.stat_chlg_step,
              let stat_mychlg_json = entity.stat_mychlg
        else {
            throw StaticErrorCD.UnexpectedConvertError
        }
        // Convert JSON to Array & return
        return (
            chlgStep: try util.convertFromJSON(jsonString: stat_chlg_step_json, type: [Int : Int].self),
            myChlg: try util.convertFromJSON(jsonString: stat_mychlg_json, type: [Int].self)
        )
    }
}

//===============================
// MARK: - Exception
//===============================
enum StaticErrorCD: LocalizedError {
    case StatRetrievalByIdentifierFailed
    case UnexpectedConvertError
    case UnexpectedFetchError
    
    var errorDescription: String?{
        switch self {
        case .StatRetrievalByIdentifierFailed:
            return "Coredata: Unable to retrieve 'Statistics' data using the provided identifier."
        case .UnexpectedConvertError:
            return "Coredata: There was an unexpected error while Convert 'Statistics' details"
        case .UnexpectedFetchError:
            return "Coredata: There was an unexpected error while Fetch 'Statistics' details"
        }
    }
}
