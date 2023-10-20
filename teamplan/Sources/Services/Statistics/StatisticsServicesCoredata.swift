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
    func getStatCoredata(identifier: String,
                         result: @escaping(Result<StatisticsObject, Error>) -> Void) {
        
        // parameter setting
        let fetchReq: NSFetchRequest<StatisticsEntity> = StatisticsEntity.fetchRequest()
        
        // Request Query
        fetchReq.predicate = NSPredicate(format: "stat_user_id == %@", identifier)
        fetchReq.fetchLimit = 1
        
        do{
            let fetchStat = try context.fetch(fetchReq)
            
            // Exception Handling: Identifier
            guard let reqStat = fetchStat.first else {
                return result(.failure(StatCDError.IdentifierFetchFailed))
            }
            return result(.success(StatisticsObject(statEntity: reqStat)))
        
            // Eception Handling: Unknown
        } catch  {
            return result(.failure(StatCDError.GetFailed))
        }
    }
    
    //================================
    // MARK: - Set Statistics
    //================================
    func setStatCoredata(reqStat: StatisticsObject,
                         result: @escaping(Result<String, Error>) -> Void) {
        
        // Create New StatisticsEntity
        let stat = StatisticsEntity(context: context)
        
        stat.stat_user_id = reqStat.stat_user_id
        stat.stat_term = Int32(reqStat.stat_term)
        stat.stat_drop = Int32(reqStat.stat_drop)
        stat.stat_proj_reg = Int32(reqStat.stat_proj_reg)
        stat.stat_proj_fin = Int32(reqStat.stat_proj_fin)
        stat.stat_proj_alert = Int32(reqStat.stat_proj_alert)
        stat.stat_proj_ext = Int32(reqStat.stat_proj_ext)
        stat.stat_todo_reg = Int32(reqStat.stat_todo_reg)
        stat.stat_chlg_step = reqStat.stat_chlg_step as NSObject
        stat.stat_mychlg = reqStat.stat_mychlg as NSObject
        stat.stat_upload_at = reqStat.stat_upload_at

        do{
            try context.save()
            return result(.success("Successfully set Statistics at CoreData"))
        } catch {
            return result(.failure(StatCDError.SetFailed))
        }
    }
    
    //===============================
    // MARK: - Exception
    //===============================
    enum StatCDError: LocalizedError {
        case IdentifierFetchFailed
        case SetFailed
        case GetFailed
        
        var errorDescription: String?{
            switch self {
            case .IdentifierFetchFailed:
                return "Failed to Fetch Statistics by identifier"
            case .SetFailed:
                return "Failed to Set Statistics at CoreData"
            case .GetFailed:
                return "Failed to Get Statistics for Unknown reason"
            }
        }
    }
}
