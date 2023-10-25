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
    // MARK: - CoreData Setting
    //================================
    let cd = CoreDataManager.shared
    var context: NSManagedObjectContext {
        return cd.context
    }
    
    //================================
    // MARK: - Get Statistics
    //================================
    func getStatistics(identifier: String,
                         result: @escaping(Result<StatisticsObject, Error>) -> Void) {
        
        // parameter setting
        let fetchReq: NSFetchRequest<StatisticsEntity> = StatisticsEntity.fetchRequest()
        
        // Request Query
        fetchReq.predicate = NSPredicate(format: "stat_user_id == %@", identifier)
        fetchReq.fetchLimit = 1
        
        do{
            // Search Statistics
            guard let statEntity = try context.fetch(fetchReq).first else {
                return result(.failure(StatCDError.StatRetrievalByIdentifierFailed))
            }
            return result(.success(StatisticsObject(statEntity: statEntity)))
        
            // Eception Handling: Unknown
        } catch  {
            return result(.failure(StatCDError.UnexpectedGetError))
        }
    }
    
    //================================
    // MARK: - Set Statistics
    //================================
    func setStatistics(reqStat: StatisticsObject,
                         result: @escaping(Result<String, Error>) -> Void) {
        
        // Create New StatisticsEntity
        let statEntity = StatisticsEntity(context: context)
        
        statEntity.stat_user_id = reqStat.stat_user_id
        statEntity.stat_term = Int32(reqStat.stat_term)
        statEntity.stat_drop = Int32(reqStat.stat_drop)
        statEntity.stat_proj_reg = Int32(reqStat.stat_proj_reg)
        statEntity.stat_proj_fin = Int32(reqStat.stat_proj_fin)
        statEntity.stat_proj_alert = Int32(reqStat.stat_proj_alert)
        statEntity.stat_proj_ext = Int32(reqStat.stat_proj_ext)
        statEntity.stat_todo_reg = Int32(reqStat.stat_todo_reg)
        statEntity.stat_chlg_step = reqStat.stat_chlg_step as NSObject
        statEntity.stat_mychlg = reqStat.stat_mychlg as NSObject
        statEntity.stat_upload_at = reqStat.stat_upload_at

        do{
            try context.save()
            return result(.success("Successfully set Statistics at CoreData"))
        } catch {
            return result(.failure(StatCDError.UnexpectedSetError))
        }
    }
    
    //================================
    // MARK: - Update Statistics
    //================================
    func updateStatistics(identifier: String, updatedStatInfo: StatisticsDTO,
                          result: @escaping(Result<String, Error>) -> Void) {
        
        // parameter setting
        let fetchReq: NSFetchRequest<StatisticsEntity> = StatisticsEntity.fetchRequest()
        
        // Request Query
        fetchReq.predicate = NSPredicate(format: "stat_user_id == %@", identifier)
        fetchReq.fetchLimit = 1
        
        do {
            guard let statEntity = try self.context.fetch(fetchReq).first else {
                throw StatCDError.StatRetrievalByIdentifierFailed
            }
            
            // Update StatisticsEntity
            statEntity.stat_term = Int32(updatedStatInfo.stat_term)
            statEntity.stat_drop = Int32(updatedStatInfo.stat_drop)
            statEntity.stat_proj_reg = Int32(updatedStatInfo.stat_proj_reg)
            statEntity.stat_proj_fin = Int32(updatedStatInfo.stat_proj_fin)
            statEntity.stat_proj_alert = Int32(updatedStatInfo.stat_proj_alert)
            statEntity.stat_proj_ext = Int32(updatedStatInfo.stat_proj_ext)
            statEntity.stat_todo_reg = Int32(updatedStatInfo.stat_todo_reg)
            statEntity.stat_chlg_step = updatedStatInfo.stat_chlg_step as NSObject
            statEntity.stat_mychlg = updatedStatInfo.stat_mychlg as NSObject
            statEntity.stat_upload_at = updatedStatInfo.stat_upload_at
            try context.save()
            
            return result(.success("Successfully Update Statistics at CoreData"))
            
        // Eception Handling: Internal Error
        } catch {
            return result(.failure(StatCDError.UnexpectedUpdateError))
        }
    }
}

//===============================
// MARK: - Exception
//===============================
enum StatCDError: LocalizedError {
    case StatRetrievalByIdentifierFailed
    case UnexpectedSetError
    case UnexpectedGetError
    case UnexpectedUpdateError
    
    var errorDescription: String?{
        switch self {
        case .StatRetrievalByIdentifierFailed:
            return "Coredata: Unable to retrieve 'Statistics' data using the provided identifier."
        case .UnexpectedSetError:
            return "Coredata: There was an unexpected error while Set 'Statistics' details"
        case .UnexpectedGetError:
            return "Coredata: There was an unexpected error while Get 'Statistics' details"
        case .UnexpectedUpdateError:
            return "Coredata: There was an unexpected error while Update 'Statistics' details"
        }
    }
}
