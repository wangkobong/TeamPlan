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
    //##### Async/Throws #####
    func setStatistics(reqStat: StatisticsObject) async throws {
        
        do{
            // Set Entity
            try setStatEntity(from: reqStat)
            
            // Store Entity
            try context.save()
        } catch {
            print("(CoreData) Error Set Statistics : \(error)")
            throw StaticErrorCD.UnexpectedSetError
        }
    }
    
    //##### Result #####
    func setStatistics(reqStat: StatisticsObject,
                         result: @escaping(Result<String, Error>) -> Void) {
        
        do{
            // Set Entity
            try setStatEntity(from: reqStat)
        
            // Store Entity
            try context.save()
            return result(.success("Successfully set Statistics at CoreData"))
        } catch {
            print("(CoreData) Error Set Statistics : \(error)")
            return result(.failure(StaticErrorCD.UnexpectedSetError))
        }
    }
    
    // Core Function
    private func setStatEntity(from reqStat: StatisticsObject) throws {
        do {
            // Convert Data
            let json_stat_chlg_step = try util.convertToJSON(data: reqStat.stat_chlg_step)
            let json_stat_mychlg = try util.convertToJSON(data: reqStat.stat_mychlg)
            
            // Set Entity
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
            
        } catch {
            print("(CoreData) Error Convert(JSON) Statistics : \(error)")
            throw StaticErrorCD.UnexpectedConvertError
        }
    }
    
    //================================
    // MARK: - Get Statistics
    //================================
    //##### Throws #####
    func getStatistics(from userId: String) throws -> StatisticsObject {
        return try getStatProcess(userId)
    }
    
    //##### Result #####
    func getStatistics(identifier: String,
                       result: @escaping(Result<StatisticsObject, Error>) -> Void) {
        do {
            let reqStat = try getStatProcess(identifier)
            return result(.success(reqStat))
        } catch {
            print("(CoreData) Error Get Statistics : \(error)")
            return result(.failure(StaticErrorCD.UnexpectedGetError))
        }
    }
    
    //##### Core Function #####
    private func getStatProcess(_ userId: String) throws -> StatisticsObject {
        // parameter setting
        let fetchReq: NSFetchRequest<StatisticsEntity> = StatisticsEntity.fetchRequest()
        
        // Request Query
        fetchReq.predicate = NSPredicate(format: "stat_user_id == %@", userId)
        fetchReq.fetchLimit = 1
        
        // Search Statistics
        guard let statEntity = try context.fetch(fetchReq).first else {
            // Exception Handling: Identifier
            throw StaticErrorCD.StatRetrievalByIdentifierFailed
        }
        // Convert Entity to Object
        let reqStat = try convertToObject(reqStat: statEntity)
        return reqStat
    }
    
    //##### Support function
    private func convertToObject(reqStat: StatisticsEntity) throws -> StatisticsObject {
        do {
            // Convert JSON String Data
            let chlgStep = try util.convertFromJSON(jsonString: reqStat.stat_chlg_step, type: [[Int : Int]].self)
            let myChlg = try util.convertFromJSON(jsonString: reqStat.stat_mychlg, type: [Int].self)
            
            // Struct Oject
            guard let stat = StatisticsObject(statEntity: reqStat, chlgStep: chlgStep, mychlg: myChlg) else {
                // Exception Handling: Fetch Error
                throw StaticErrorCD.UnexpectedFetchError
            }
            return stat
            
        } catch {
            print("(CoreData) Error Convert(Object) Statistics : \(error)")
            throw StaticErrorCD.UnexpectedConvertError
        }
    }
    
    //================================
    // MARK: - Update Statistics
    //================================
    //##### Async/Throws #####
    func updateStatistics(from identifier: String, to updatedStat: StatisticsDTO) async throws {        // parameter setting
        let fetchReq: NSFetchRequest<StatisticsEntity> = StatisticsEntity.fetchRequest()
        
        // Request Query
        fetchReq.predicate = NSPredicate(format: "stat_user_id == %@", identifier)
        fetchReq.fetchLimit = 1
        
        do {
            // Search StatisticsEntity
            guard let statEntity = try self.context.fetch(fetchReq).first else {
                // Exception Handling: Identifier
                throw StaticErrorCD.StatRetrievalByIdentifierFailed
            }
            if try checkUpdate(from: statEntity, to: updatedStat) {
                try context.save()
            } else {
                throw StaticErrorCD.NoUpdateNecessary
            }
        } catch {
            // Eception Handling: Internal Error
            print("(CoreData) Error Update Statistics : \(error)")
            throw StaticErrorCD.UnexpectedUpdateError
        }
    }
    
    //##### Result #####
    //TODO: Adjust Async
    func updateStatistics(from identifier: String, to updatedStat: StatisticsDTO,
                          result: @escaping(Result<String, Error>) -> Void) {
        // parameter setting
        let fetchReq: NSFetchRequest<StatisticsEntity> = StatisticsEntity.fetchRequest()
        
        // Request Query
        fetchReq.predicate = NSPredicate(format: "stat_user_id == %@", identifier)
        fetchReq.fetchLimit = 1
        
        do {
            // Search StatisticsEntity
            guard let statEntity = try self.context.fetch(fetchReq).first else {
                // Exception Handling: Identifier
                throw StaticErrorCD.StatRetrievalByIdentifierFailed
            }
            // Update StatisticsEntity
            if try checkUpdate(from: statEntity, to: updatedStat) {
                try context.save()
                return result(.success("Successfully Update Statistics at CoreData"))
            } else {
                return result(.failure(StaticErrorCD.NoUpdateNecessary))
            }
        
        } catch {
            // Eception Handling: Internal Error
            print("(CoreData) Error Update Statistics : \(error)")
            return result(.failure(StaticErrorCD.UnexpectedUpdateError))
        }
    }
    
    //##### Core function
    private func updateStatProcess(from userId: String, to updatedStat: StatisticsDTO) async throws {

    }
    
    //##### Support function
    private func checkUpdate(from statEntity: StatisticsEntity, to updatedStat: StatisticsDTO) throws -> Bool {
        // Convert Array to JSON
        let json_stat_chlg_step = try util.convertToJSON(data: updatedStat.stat_chlg_step)
        let json_stat_mychlg = try util.convertToJSON(data: updatedStat.stat_mychlg)
        
        // Update StatisticsEntity
        var isUpdated = false
        isUpdated = util.updateFieldIfNeeded(&statEntity.stat_term, newValue: Int32(updatedStat.stat_term)) || isUpdated
        isUpdated = util.updateFieldIfNeeded(&statEntity.stat_drop, newValue: Int32(updatedStat.stat_drop)) || isUpdated
        isUpdated = util.updateFieldIfNeeded(&statEntity.stat_proj_reg, newValue: Int32(updatedStat.stat_proj_reg)) || isUpdated
        isUpdated = util.updateFieldIfNeeded(&statEntity.stat_proj_fin, newValue: Int32(updatedStat.stat_proj_fin)) || isUpdated
        isUpdated = util.updateFieldIfNeeded(&statEntity.stat_proj_alert, newValue: Int32(updatedStat.stat_proj_alert)) || isUpdated
        isUpdated = util.updateFieldIfNeeded(&statEntity.stat_proj_ext, newValue: Int32(updatedStat.stat_proj_ext)) || isUpdated
        isUpdated = util.updateFieldIfNeeded(&statEntity.stat_todo_reg, newValue: Int32(updatedStat.stat_todo_reg)) || isUpdated
        isUpdated = util.updateFieldIfNeeded(&statEntity.stat_chlg_step, newValue: json_stat_chlg_step) || isUpdated
        isUpdated = util.updateFieldIfNeeded(&statEntity.stat_mychlg, newValue: json_stat_mychlg) || isUpdated
        isUpdated = util.updateFieldIfNeeded(&statEntity.stat_upload_at, newValue: updatedStat.stat_upload_at) || isUpdated
        
        return isUpdated
    }

    //================================
    // MARK: - Delete Statistics
    //================================
    //##### Async/Await #####
    func deleteStatistics(identifier: String) async throws {
        
        // parameter setting
        let fetchReq: NSFetchRequest<StatisticsEntity> = StatisticsEntity.fetchRequest()
        
        // Request Query
        fetchReq.predicate = NSPredicate(format: "stat_user_id == %@", identifier)
        fetchReq.fetchLimit = 1
        
        do {
            guard let statEntity = try context.fetch(fetchReq).first else {
                // Exception Handling: Identifier
                throw StaticErrorCD.StatRetrievalByIdentifierFailed
            }
            // Delete StatEntity
            self.context.delete(statEntity)
            try context.save()
            
        } catch {
            print("(CoreData) Error Delete Statistics : \(error)")
            throw StaticErrorCD.UnexpectedDeleteError
        }
    }
}

//===============================
// MARK: - Exception
//===============================
enum StaticErrorCD: LocalizedError {
    case UnexpectedSetError
    case UnexpectedGetError
    case UnexpectedUpdateError
    case NoUpdateNecessary
    case UnexpectedDeleteError
    case StatRetrievalByIdentifierFailed
    case UnexpectedFetchError
    case UnexpectedConvertError
    
    var errorDescription: String?{
        switch self {
        case .UnexpectedSetError:
            return "Coredata: There was an unexpected error while Set 'Statistics' details"
        case .UnexpectedGetError:
            return "Coredata: There was an unexpected error while Get 'Statistics' details"
        case .UnexpectedUpdateError:
            return "Coredata: There was an unexpected error while Update 'Statistics' details"
        case .NoUpdateNecessary:
            return "Coredata: 'Statistics' Update is No Necessary"
        case .UnexpectedDeleteError:
            return "Coredata: There was an unexpected error while Delete 'Statistics' details"
        case .StatRetrievalByIdentifierFailed:
            return "Coredata: Unable to retrieve 'Statistics' data using the provided identifier."
        case .UnexpectedFetchError:
            return "Coredata: There was an unexpected error while Fetch 'Statistics' details"
        case .UnexpectedConvertError:
            return "Coredata: There was an unexpected error while Convert 'Statistics' details"
        }
    }
}
