//
//  AccessLog.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/10/20.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation

//============================
// MARK: Entity
//============================
struct AccessLog{
    
    //--------------------
    // content
    //--------------------
    let log_id: Int
    let log_user_id: String
    var log_access: [Date]
    var log_upload_at: Date
    
    //--------------------
    // constructor
    //--------------------
    // Default
    init(){
        self.log_id = 0
        self.log_user_id = "unknown"
        self.log_access = []
        self.log_upload_at = Date()
    }
    
    // Signup
    init(logId: Int, userId: String, accessDate: Date){
        self.log_id = logId
        self.log_user_id = userId
        self.log_access = [accessDate]
        self.log_upload_at = accessDate
    }
    
    // Coredata
    init?(with entity: AccessLogEntity, log: [Date]) {
        guard let userId = entity.log_user_id,
              let uploadAt = entity.log_upload_at
        else {
            return nil
        }
        self.log_id = Int(entity.log_id)
        self.log_user_id = userId
        self.log_access = log
        self.log_upload_at = uploadAt
    }
    
    // Firestore
    init?(data: [String : Any]) {
        guard let log_id = data["log_id"] as? Int,
              let log_user_id = data["log_user_id"] as? String,
              let log_upload_at_string = data["log_upload_at"] as? String,
              let log_upload_at = DateFormatter.standardFormatter.date(from: log_upload_at_string),
              let log_access_string = data["log_access"] as? [String]
        else {
            return nil
        }
        // Data Convert
        let logDates = log_access_string.compactMap { DateFormatter.standardFormatter.date(from: $0) }
        guard logDates.count == log_access_string.count else {
            return nil
        }
        // Assigning values
        self.log_id = log_id
        self.log_user_id = log_user_id
        self.log_access = logDates
        self.log_upload_at = log_upload_at
    }
    
    //--------------------
    // Function
    //--------------------
    mutating func updateUploadAt(with newDate: Date) {
        self.log_upload_at = newDate
    }
    
    func toDictionary() -> [String : Any] {
        let logStrings = log_access.map { DateFormatter.standardFormatter.string(from: $0) }
        let logUploadAtString = DateFormatter.standardFormatter.string(from: log_upload_at)
        
        return [
            "log_id" : self.log_id,
            "log_user_id" : self.log_user_id,
            "log_access" : logStrings,
            "log_upload_at" : logUploadAtString
        ]
    }
}

//============================
// MARK: Entity
//============================
struct AccessLogUpdateDTO{
    
    //--------------------
    // content
    //--------------------
    let userId: String
    let logId: Int
    
    var newAccessDate: Date?
    var newUploadAt: Date?
    
    //--------------------
    // constructor
    //--------------------
    init(userId: String, logId: Int,
         newAccessDate: Date? = nil,
         newUploadAt: Date? = nil)
    {
        self.userId = userId
        self.logId = logId
        self.newAccessDate = newAccessDate
        self.newUploadAt = newUploadAt
    }
}
