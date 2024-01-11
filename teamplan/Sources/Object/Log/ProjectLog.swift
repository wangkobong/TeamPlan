//
//  ProjectLog.swift
//  teamplan
//
//  Created by 주찬혁 on 1/5/24.
//  Copyright © 2024 team1os. All rights reserved.
//

import Foundation

//============================
// MARK: Entity
//============================
struct ProjectLog{
    
    //--------------------
    // content
    //--------------------
    let userId: String
    let projectId: Int
    
    var title: String
    var status: ProjectStatus
    var extendInfo: [Int:Date]
    var alertCount: Int
    var todoCount: Int
    var startAt: Date
    var registAt: Date
    var deadline: [Date]
    var finishAt: Date
    
    //--------------------
    // constructor
    //--------------------
    // ProjectIndex
    init(with dto: ProjectSetDTO, id projectId: Int, by userId: String, at registDate: Date){
        self.userId = userId
        self.projectId = projectId
        self.title = dto.title
        self.status = .ongoing
        self.extendInfo = [:]
        self.alertCount = 0
        self.todoCount = 0
        self.startAt = dto.startedAt
        self.registAt = registDate
        self.deadline = [dto.deadline]
        self.finishAt = registDate
    }
    // Coredata
    init?(from entity: ProjectLogEntity, info: [Int:Date], deadline: [Date]) {
        guard let userId = entity.log_user_id,
              let title = entity.log_title,
              let stringStatus = entity.log_status,
              let status = ProjectStatus(rawValue: stringStatus),
              let startAt = entity.log_start_at,
              let registAt = entity.log_regist_at,
              let finishAt = entity.log_finish_at
        else {
            return nil
        }
        self.userId = userId
        self.projectId = Int(entity.log_project_id)
        self.title = title
        self.status = status
        self.extendInfo = info
        self.alertCount = Int(entity.log_alert_count)
        self.todoCount = Int(entity.log_todo_count)
        self.startAt = startAt
        self.registAt = registAt
        self.deadline = deadline
        self.finishAt = finishAt
    }
    // Firestore
    init?(firestoreData: [String: Any]) {
        guard let userId = firestoreData["log_user_id"] as? String,
              let projectId = firestoreData["log_project_id"] as? Int,
              let title = firestoreData["log_title"] as? String,
              let statusString = firestoreData["log_status"] as? String,
              let status = ProjectStatus(rawValue: statusString),
              let extendInfoDict = firestoreData["log_extend_info"] as? [String : String],
              let alertCount = firestoreData["log_alert_count"] as? Int,
              let todoCount = firestoreData["log_todo_count"] as? Int,
              let startAtString = firestoreData["log_start_at"] as? String,
              let startAt = DateFormatter.standardFormatter.date(from: startAtString),
              let registAtString = firestoreData["log_regist_at"] as? String,
              let registAt = DateFormatter.standardFormatter.date(from: registAtString),
              let finishAtString = firestoreData["log_finish_at"] as? String,
              let finishAt = DateFormatter.standardFormatter.date(from: finishAtString),
              let deadlineStrings = firestoreData["log_deadline"] as? [String]
        else {
            return nil
        }
        
        let deadline = deadlineStrings.compactMap { DateFormatter.standardFormatter.date(from: $0) }
        let extendInfo = extendInfoDict
            .compactMapKeys { Int($0) }
            .compactMapValues { DateFormatter.standardFormatter.date(from: $0) }
        
        // Assigning values
        self.userId = userId
        self.projectId = projectId
        self.title = title
        self.status = status
        self.extendInfo = extendInfo
        self.alertCount = alertCount
        self.todoCount = todoCount
        self.startAt = startAt
        self.registAt = registAt
        self.deadline = deadline
        self.finishAt = finishAt
    }
    
    //--------------------
    // function
    //--------------------
    func toDictionary() -> [String: Any] {
        let extendInfoString = extendInfo
            .mapKeys { String($0) }
            .mapValues { DateFormatter.standardFormatter.string(from: $0) }

        return [
            "log_user_id": self.userId,
            "log_project_id": self.projectId,
            "log_title": self.title,
            "log_status": self.status.rawValue,
            "log_extend_info": extendInfoString,
            "log_alert_count": self.alertCount,
            "log_todo_count": self.todoCount,
            "log_start_at": DateFormatter.standardFormatter.string(from: self.startAt),
            "log_regist_at": DateFormatter.standardFormatter.string(from: self.registAt),
            "log_finish_at": DateFormatter.standardFormatter.string(from: self.finishAt),
            "log_deadline": deadline.map { DateFormatter.standardFormatter.string(from: $0) }
        ]
    }
}

//============================
// MARK: DTO
//============================
struct ProjectLogUpdateDTO{
    
    //--------------------
    // content
    //--------------------
    let userId: String
    let projectId: Int
    
    var newTitle: String?
    var newStatus: ProjectStatus?
    var newExtendInfo: [Int:Date]?
    var newAlertCount: Int?
    var newTodoCount: Int?
    var newDeadline: Date?
    var newFinishAt: Date?
    
    //--------------------
    // content
    //--------------------
    init(userId: String, projectId: Int,
         title: String? = nil,
         status: ProjectStatus? = nil,
         extendInfo: [Int : Date]? = nil,
         alertCount: Int? = nil,
         todoCount: Int? = nil,
         deadline: Date? = nil,
         finishAt: Date? = nil)
    {
        self.userId = userId
        self.projectId = projectId
        self.newTitle = title
        self.newStatus = status
        self.newExtendInfo = extendInfo
        self.newAlertCount = alertCount
        self.newTodoCount = todoCount
        self.newDeadline = deadline
        self.newFinishAt = finishAt
    }
}

//============================
// MARK: Enum
//============================
enum ProjectStatus: String{
    case ongoing = "Ongoing Project"
    case finish = "Finished Project"
    case explosioned = "Explosioned Project"
}
