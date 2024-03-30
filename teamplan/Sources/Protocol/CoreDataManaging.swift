//
//  EntityManagingProtocol.swift
//  teamplan
//
//  Created by 크로스벨 on 3/15/24.
//  Copyright © 2024 team1os. All rights reserved.
//

import CoreData

// MARK: - Coredata Controller
protocol CoredataProtocol {
    var container: NSPersistentContainer { get }
    var context: NSManagedObjectContext { get }
}

enum CoredataConfig {
    static let defaultModel = "Coredata"
}

final class CoredataController: CoredataProtocol {
    private let modelName: String
    
    // only initialize when it needed
    lazy var container: NSPersistentContainer = {
        let container = NSPersistentContainer(name: modelName)
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                fatalError("[Coredata] Unable to load persistent container: \(error)")
            }
        }
        return container
    }()
    var context: NSManagedObjectContext {
        return container.viewContext
    }
    
    init(modelName: String = CoredataConfig.defaultModel) {
        self.modelName = modelName
    }
}

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


// MARK: - ReadOnly
protocol ReadOnlyObjectManage: BasicObjectManage {
    func getObject(with userId: String) throws -> Object
}



// MARK: - Full Manage
protocol FullObjectManage: ReadOnlyObjectManage {
    associatedtype DTO
    
    func setObject(with object: Object) throws
    func updateObject(with dto: DTO) throws
    func deleteObject(with userId: String) throws
}

protocol ChallengeObjectManage: BasicObjectManage {
    associatedtype DTO
    
    func setObject(with object: Object) throws
    func getObject(with challengeId: Int, and userId: String) throws -> Object
    func getObjects(with userId: String) throws -> [Object]
    func updateObject(with dto: DTO) throws
    func deleteObject(with userId: String) throws
}


protocol LogObjectManage: BasicObjectManage {
    
    func setObject(with object: Object) throws
    func getObject(with userId: String) throws -> Object
    func getObjects(with userId: String) throws -> [Object]
    func getTargetObjects(with userId: String, and syncedAt: Date) throws -> [Object]
    func deleteObject(with userId: String) throws
}

protocol ProjectObjectManage: BasicObjectManage {
    associatedtype DTO
    associatedtype CardDTO
    
    func setObject(with object: Object) throws
    func getDTO(with userId: String) throws -> [CardDTO]
    func getObject(with userId: String, and projectId: Int) throws -> Object
    func getObjects(with userId: String) throws -> [Object]
    func updateObject(with dto: DTO) throws
    func deleteObject(with userId: String, and projectId: Int) throws
}

protocol TodoObjectManage: BasicObjectManage {
    associatedtype DTO
    
    func setObject(with object: Object) throws
    func getObject(userId: String, projectId: Int, todoId: Int) throws -> Object
    func getObjects(userId: String, projectId: Int) throws -> [Object]
    func updateObject(updated: DTO) throws
    func deleteObject(userId: String, projectId: Int, todoId: Int) throws
}


// MARK: - Enum
enum EntityPredicate {
    case coreValue
    case user
    case stat
    case multiChallenge
    case accessLog
    case projectList
    case project
    case singleChallenge
    case targetLog
    
    var format: String {
        switch self {
        case .coreValue, .user, .stat, .multiChallenge, .accessLog, .projectList:
            return "user_id == %@"
        case .project:
            return "user_id == %@ AND project_id == %d"
        case .singleChallenge:
            return "user_id == %@ AND challenge_id == %d"
        case .targetLog:
            return "user_id == %@ AND access_record > %@"
        }
    }
}

enum EntitySortBy: String {
    case date = "access_record"
}
