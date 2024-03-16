//
//  EntityManagingProtocol.swift
//  teamplan
//
//  Created by 크로스벨 on 3/15/24.
//  Copyright © 2024 team1os. All rights reserved.
//

import CoreData

// MARK: Full Manage
protocol FullEntityManage {
    associatedtype Entity: NSManagedObject
    associatedtype Object
    associatedtype DTO
    
    func setObject(with object: Object) throws
    func getObject(with userId: String) throws -> Object
    func updateObject(with dto: DTO) throws
    func deleteObject(with userId: String) throws
}


// MARK: Read Only
protocol ReadOnlyEntityManage: AnyObject {
    associatedtype Entity: NSManagedObject
    associatedtype Object
    
    var context: NSManagedObjectContext { get }
    
    func getObject(with userId: String) throws -> Object
}

extension ReadOnlyEntityManage {
    
    func fetchEntity(with fetchReq: NSPredicate) throws -> Entity? {
        
        let request = Entity.fetchRequest()
        request.predicate = fetchReq
        
        let result = try context.fetch(request)
        return result.first as? Entity
    }
}

// MARK: Predicate
enum EntityPredicate: String{
    case coreValue, user, stat = "user_id == %@"
    case project = "user_id == %@ AND project_id == %d"
    case challenge = "user_id == %@ AND challenge_id == %d"
    case accessLog = "user_id == %@ AND log_id == %d"
}
