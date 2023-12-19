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
    func updateStatistics(to updatedStat: StatisticsDTO) throws {
        
        // parameter setting
        let fetchReq: NSFetchRequest<StatisticsEntity> = StatisticsEntity.fetchRequest()
        
        // Request Query
        fetchReq.predicate = NSPredicate(format: "stat_user_id == %@", updatedStat.stat_user_id)
        fetchReq.fetchLimit = 1
        
        // Search Data
        guard let reqStat = try self.context.fetch(fetchReq).first else {
            throw StaticErrorCD.StatRetrievalByIdentifierFailed
        }
        // Update Data
        if try checkUpdate(from: reqStat, to: updatedStat) {
            try context.save()
        }
    }
    // Support function
    private func checkUpdate(from origin: StatisticsEntity, to updated: StatisticsDTO) throws -> Bool {
        // Convert Array to JSON
        let json_stat_chlg_step = try util.convertToJSON(data: updated.stat_chlg_step)
        let json_stat_mychlg = try util.convertToJSON(data: updated.stat_mychlg)
        
        // Update Entity
        var isUpdated = false
        isUpdated = util.updateFieldIfNeeded(&origin.stat_term, newValue: Int32(updated.stat_term)) || isUpdated
        isUpdated = util.updateFieldIfNeeded(&origin.stat_drop, newValue: Int32(updated.stat_drop)) || isUpdated
        isUpdated = util.updateFieldIfNeeded(&origin.stat_proj_reg, newValue: Int32(updated.stat_proj_reg)) || isUpdated
        isUpdated = util.updateFieldIfNeeded(&origin.stat_proj_fin, newValue: Int32(updated.stat_proj_fin)) || isUpdated
        isUpdated = util.updateFieldIfNeeded(&origin.stat_proj_alert, newValue: Int32(updated.stat_proj_alert)) || isUpdated
        isUpdated = util.updateFieldIfNeeded(&origin.stat_proj_ext, newValue: Int32(updated.stat_proj_ext)) || isUpdated
        isUpdated = util.updateFieldIfNeeded(&origin.stat_todo_reg, newValue: Int32(updated.stat_todo_reg)) || isUpdated
        isUpdated = util.updateFieldIfNeeded(&origin.stat_chlg_step, newValue: json_stat_chlg_step) || isUpdated
        isUpdated = util.updateFieldIfNeeded(&origin.stat_mychlg, newValue: json_stat_mychlg) || isUpdated
        isUpdated = util.updateFieldIfNeeded(&origin.stat_upload_at, newValue: updated.stat_upload_at) || isUpdated
        
        return isUpdated
    }

    //================================
    // MARK: - Delete Statistics
    //================================
    func deleteStatistics(identifier: String) throws {
        
        // parameter setting
        let fetchReq: NSFetchRequest<StatisticsEntity> = StatisticsEntity.fetchRequest()
        
        // Request Query
        fetchReq.predicate = NSPredicate(format: "stat_user_id == %@", identifier)
        fetchReq.fetchLimit = 1
        
        // Search Data
        guard let statEntity = try context.fetch(fetchReq).first else {
            throw StaticErrorCD.StatRetrievalByIdentifierFailed
        }
        // Delete Data
        context.delete(statEntity)
        try context.save()
    }
}

//===============================
// MARK: - Exception
//===============================
enum StaticErrorCD: LocalizedError {
    case StatRetrievalByIdentifierFailed
    case UnexpectedConvertError
    
    var errorDescription: String?{
        switch self {
        case .StatRetrievalByIdentifierFailed:
            return "Coredata: Unable to retrieve 'Statistics' data using the provided identifier."
        case .UnexpectedConvertError:
            return "Coredata: There was an unexpected error while Convert 'Statistics' details"
        }
    }
}
