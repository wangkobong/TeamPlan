//
//  EntityManagingProtocol.swift
//  teamplan
//
//  Created by 크로스벨 on 3/15/24.
//  Copyright © 2024 team1os. All rights reserved.
//

import CoreData

// MARK: - Basic
protocol BasicObjectManage {
    associatedtype Entity: NSManagedObject
    associatedtype Object
    
}

extension BasicObjectManage {
    func fetchEntity(
        with fetchReq: NSFetchRequest<Entity>,
        and context: NSManagedObjectContext) throws -> Entity? {
        
        let result = try context.fetch(fetchReq)
        return result.first
    }
}

// MARK: - Full Manage
protocol FullObjectManage: BasicObjectManage {
    associatedtype DTO
    
    func setObject(with object: Object) throws -> Bool
    func getObject(with userId: String) throws -> Object
    func updateObject(with dto: DTO) throws -> Bool
    func deleteObject(with userId: String) throws
    func isObjectExist(with userId: String) -> Bool
}


// MARK: - CoreValue
protocol CoreValueObjectManage: BasicObjectManage {
    
    func setObject(with object: Object) -> Bool
    func getObject(with userId: String) throws -> Object
    func deleteObject(with userId: String) throws
    func isObjectExist(with userId: String) -> Bool
}


// MARK: - Notification
protocol NotificationObjectManage: BasicObjectManage {
    
    func setObject(with object: Object) async throws
    func getFullObject(with userId: String) async throws -> [Object]
    func getCategoryObject(with userId: String, and category: NotificationCategory) async throws -> [Object]
    func deleteObject(with userId: String, and notifyId: Int) async throws
    func deleteObjects(with userId: String, and notifyIds: [Int]) async throws
}


// MARK: - Challenge
protocol ChallengeObjectManage: BasicObjectManage {
    associatedtype DTO
    
    func setObject(with object: Object) -> Bool
    func getObject(with challengeId: Int, and userId: String) async throws -> Object
    func deleteObject(with userId: String) async throws
    func updateObject(with dto: DTO) throws
    
    func getObjects(with userId: String) throws -> [Object]
    func getObjects(with userId: String) async throws -> [Object]
    func getTartgetObjects(with userId: String, syncDate: Date) async throws -> [Object]
    func countCompleteObjects(with userId: String) async throws -> Int
    func isObjectExist(with userId: String) -> Bool
}


// MARK: - Log
protocol AccessLogObjectManage: BasicObjectManage {
    
    func setObject(with object: Object) -> Bool
    
    func getLatestObject(with userId: String) throws -> Object
    func getFullObjects(with userId: String) throws -> [Object]
    
    func deleteObject(with userId: String) throws
    func isObjectExist(with userId: String) -> Bool
}

protocol ProjectLogObjectManage: BasicObjectManage {
    
    func setObject(with object: Object) -> Bool
    func getObjects(with projectId: Int, and userId: String) throws -> [Object]
    func deleteObject(with projectId: Int, and userId: String) async throws
}

// MARK: - Project
protocol ProjectObjectManage: BasicObjectManage {
    associatedtype UpdateDTO
    associatedtype HomeDTO
    associatedtype BackgroundDTO
    
    func setObject(with object: Object) -> Bool
    
    func getObject(with userId: String, and projectId: Int) throws -> Object
    func getObjects(with userId: String) throws -> [Object]
    func getValidObjects(with userId: String) throws -> [Object]
    
    func getIdList(with userId: String) throws -> [Int]
    func getHomeDTOList(with userId: String) throws -> [HomeDTO]
    func getBackgroundDTOList(with userId:String) throws -> [BackgroundDTO]
    
    func updateObject(with dto: UpdateDTO) throws -> Bool
    func deleteObject(with userId: String, and projectId: Int) throws
    func deleteTruncateObject(with userId: String) throws -> Bool
}


// MARK: - Todo
protocol TodoObjectManage: BasicObjectManage {
    associatedtype DTO
    
    func setObject(with object: Object) throws -> Bool
    func getObject(userId: String, projectId: Int, todoId: Int) throws -> Object
    func getObjects(userId: String, projectId: Int) throws -> [Object]
    func updateObject(updated: DTO) throws -> Bool
    func deleteObject(userId: String, projectId: Int, todoId: Int) throws
}


// MARK: - Enum
enum EntityPredicate {
    case user
    case stat
    case coreValue
    
    case singleNotify
    case fullNotify
    case categoryNotify
    
    case accessLog
    case targetLog
    case projectExtendLog
    case totalProjectExtendLog
    
    case project
    case projectTotalList
    case projectValidList
    case projectUploadList
    case projectTruncateList
    
    case fullChallenge
    case singleChallenge
    case completeChallenge
    case targetChallenge
    
    var format: String {
        switch self {
        // user data
        case .coreValue, .user, .stat:
            return "user_id == %@"
            
        // notification
        case .singleNotify:
            return "user_id == %@ AND notify_id == %d"
        case .fullNotify:
            return "user_id == %@"
        case .categoryNotify:
            return "user_id == %@ AND category == %d"
            
        // challenge
        case .fullChallenge:
            return "user_id == %@"
        case .singleChallenge:
            return "user_id == %@ AND challenge_id == %d"
        case .completeChallenge:
            return "user_id == %@ AND status == %@"
        case .targetChallenge:
            return "user_id == %@ AND (selected_at > %@ OR unselected_at > %@ OR finished_at > %@)"
            
        // project
        case .project:
            return "user_id == %@ AND project_id == %d"
        case .projectTotalList:
            return "user_id == %@"
        case .projectValidList:
            return "user_id == %@ AND (status == %d OR status == %d)"
        case .projectUploadList:
            return "user_id == %@ AND (status == %d OR status == %d OR status == %d)"
        case .projectTruncateList:
            return "user_id == %@ AND (status == %d OR status == %d OR status == %d OR status == %d)"
            
        // accesslog
        case .accessLog:
            return "user_id == %@"
        case .targetLog:
            return "user_id == %@ AND access_record > %@"
            
        // projectLog
        case .projectExtendLog:
            return "user_id == %@ AND project_id == %d"
        case .totalProjectExtendLog:
            return "user_id == %@"
        }
    }
}

enum EntitySortBy: String {
    case date = "access_record"
}
