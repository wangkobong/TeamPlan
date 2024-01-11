//
//  ProjectLogServicesCoredata.swift
//  teamplan
//
//  Created by 주찬혁 on 1/5/24.
//  Copyright © 2024 team1os. All rights reserved.
//

import Foundation
import CoreData

//================================
// MARK: - Parameter
//================================
final class ProjectLogServicesCoredata{

    let util = Utilities()
    let cm = CoreDataManager.shared
    var context: NSManagedObjectContext {
        return cm.context
    }
}

//================================
// MARK: - Main Function
//================================
extension ProjectLogServicesCoredata{
    
    //--------------------
    // Set
    //--------------------
    func setLog(with newLog: ProjectLog) throws {
        // Create Entity
        try setLogEntity(with: newLog)
        
        // Set Entity
        try context.save()
    }
    
    //--------------------
    // Get
    //--------------------
    // Single
    func getLog(with projectId: Int, by userId: String) throws -> ProjectLog {
        // Fetch Entity
        let entity = try fetchEntity(with: projectId, by: userId)
        
        // Convert & Return
        return try convertToLog(from: entity)
    }
    
    // List
    func getLogList(with userId: String) throws -> [ProjectLog] {
        // Fetch Entities
        let entities = try fetchEntities(with: userId)
        
        // Convert & Return
        return try entities.map { try convertToLog(from: $0) }
    }
    
    //--------------------
    // Update
    //--------------------
    func updateLog(with dto: ProjectLogUpdateDTO) throws {
        // Fetch Entity
        let entity = try fetchEntity(with: dto.projectId, by: dto.userId)
        
        // Update check
        if try checkUpdate(from: entity, with: dto) {
            try context.save()
        }
    }
    
    //--------------------
    // Delete
    //--------------------
    func deleteLog(with projectId: Int, by userId: String) throws {
        // Fetch Entity
        let entity = try fetchEntity(with: projectId, by: userId)
        
        // Delete & Apply
        context.delete(entity)
        try context.save()
    }
}

//================================
// MARK: - Support Function
//================================
extension ProjectLogServicesCoredata{
    
    // Fetch Entity
    private func fetchEntity(with projectId: Int, by userId: String) throws -> ProjectLogEntity {
        // parameter setting
        let fetchReq: NSFetchRequest<ProjectLogEntity> = ProjectLogEntity.fetchRequest()
        // request query
        fetchReq.predicate = NSPredicate(format: "log_project_id == %d AND log_user_id == %@", projectId, userId)
        fetchReq.fetchLimit = 1
        // convert & return
        guard let entity = try context.fetch(fetchReq).first else {
            throw ProjectLogErrorCD.UnexpectedFetchError
        }
        return entity
    }
    
    // Fetch Entities
    private func fetchEntities(with userId: String) throws -> [ProjectLogEntity] {
        // Parameter setting
        let fetchReq: NSFetchRequest<ProjectLogEntity> = ProjectLogEntity.fetchRequest()
        
        // Request Query
        fetchReq.predicate = NSPredicate(format: "log_user_id == %@", userId)
        
        // Return
        do {
            return try context.fetch(fetchReq)
        } catch {
            throw ProjectLogErrorCD.UnexpectedSearchError
        }
    }
    //----------------------------------------------
    
    // Set Entity
    private func setLogEntity(with log: ProjectLog) throws {
        // Convert To JSON
        let extendInfoString = try util.convertToJSON(data: log.extendInfo)
        let deadlineString = try util.convertToJSON(data: log.deadline)
        
        // Set Entity
        let entity = ProjectLogEntity(context: context)
        entity.log_user_id = log.userId
        entity.log_project_id = Int32(log.projectId)
        entity.log_title = log.title
        entity.log_extend_info = extendInfoString
        entity.log_alert_count = Int32(log.alertCount)
        entity.log_todo_count = Int32(log.todoCount)
        entity.log_start_at = log.startAt
        entity.log_regist_at = log.registAt
        entity.log_deadline = deadlineString
    }
    //----------------------------------------------
    
    // Convert: to Dictionary
    private func convertToDict(with entity: ProjectLogEntity) throws -> [Int:Date] {
        guard let stringData = entity.log_extend_info else {
            throw ProjectLogErrorCD.UnexpectedConvertError
        }
        return try util.convertFromJSON(jsonString: stringData, type: [Int:Date].self)
    }
    
    // Convert: to Array
    private func convertToArray(with entity: ProjectLogEntity) throws -> [Date] {
        guard let stringData = entity.log_deadline else {
            throw ProjectLogErrorCD.UnexpectedConvertError
        }
        return try util.convertFromJSON(jsonString: stringData, type: [Date].self)
    }

    // Convert: to Object
    private func convertToLog(from entity: ProjectLogEntity) throws -> ProjectLog {
        // Convert Element
        let extendInfo = try convertToDict(with: entity)
        let deadline = try convertToArray(with: entity)
        
        guard let log = ProjectLog(from: entity, info: extendInfo, deadline: deadline) else {
            throw ProjectLogErrorCD.UnexpectedConvertError
        }
        return log
    }
    //----------------------------------------------
    
    // Update Check
    private func checkUpdate(from origin: ProjectLogEntity, with updated: ProjectLogUpdateDTO) throws -> Bool {
        var isUpdated = false
        
        if let newTitle = updated.newTitle {
            isUpdated = util.updateFieldIfNeeded(&origin.log_title, newValue: newTitle) || isUpdated
        }
        if let newStatus = updated.newStatus {
            let newStatusString = newStatus.rawValue
            isUpdated = util.updateFieldIfNeeded(&origin.log_status, newValue: newStatusString) || isUpdated
        }
        if let newAlertCount = updated.newAlertCount {
            isUpdated = util.updateFieldIfNeeded(&origin.log_alert_count, newValue: Int32(newAlertCount)) || isUpdated
        }
        if let newTodoCount = updated.newTodoCount {
            isUpdated = util.updateFieldIfNeeded(&origin.log_todo_count, newValue: Int32(newTodoCount)) || isUpdated
        }
        if let newFinishAt = updated.newFinishAt {
            isUpdated = util.updateFieldIfNeeded(&origin.log_finish_at, newValue: newFinishAt) || isUpdated
        }
        if let newExtendInfo = updated.newExtendInfo {
            // Fetch & Merge newData
            var extendInfo = try util.convertFromJSON(jsonString: origin.log_extend_info, type: [Int: Date].self)
            extendInfo.merge(newExtendInfo) { (_, new) in new }

            // Convert merged data back to JSON
            let stringExtendInfo = try util.convertToJSON(data: extendInfo)

            // Apply Update
            isUpdated = util.updateFieldIfNeeded(&origin.log_extend_info, newValue: stringExtendInfo) || isUpdated
        }
        if let newDeadline = updated.newDeadline {
            // Fetch & Merge newData
            var deadline = try util.convertFromJSON(jsonString: origin.log_deadline, type: [Date].self)
            deadline.append(newDeadline)

            // Convert merged data back to JSON
            let stringDeadline = try util.convertToJSON(data: deadline)

            // Apply Update
            isUpdated = util.updateFieldIfNeeded(&origin.log_deadline, newValue: stringDeadline) || isUpdated
        }
        return isUpdated
    }
}

//===============================
// MARK: - Exception
//===============================
enum ProjectLogErrorCD: LocalizedError {
    case UnexpectedFetchError
    case UnexpectedConvertError
    case UnexpectedSearchError
    case UnexpectedNilError
    
    var errorDescription: String?{
        switch self {
        case .UnexpectedFetchError:
            return "Coredata: There was an unexpected error while Fetch 'ProjectLog' details"
        case .UnexpectedConvertError:
            return "Coredata: There was an unexpected error while Convert 'ProjectLog' details"
        case .UnexpectedSearchError:
            return "Coredata: There was an unexpected error while Search 'ProjectLog' details"
        case .UnexpectedNilError:
            return "Coredata: There was an unexpected Nil error while Get 'ProjectLog'"
        }
    }
}
