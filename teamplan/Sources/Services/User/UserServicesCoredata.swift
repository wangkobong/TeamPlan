//
//  UserServiceCoredata.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/08/22.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation
import CoreData

final class UserServicesCoredata{
    
    //================================
    // MARK: - Parameter
    //================================
    let util = Utilities()
    let cm = CoreDataManager.shared
    var context: NSManagedObjectContext {
        return cm.context
    }
}

//================================
// MARK: - Main Function
//================================
extension UserServicesCoredata{
    
    //--------------------
    // Set
    //--------------------
    func setUser(with newUser: UserObject, and setDate: Date) throws {
        // Create Entity
        createEntity(with: newUser, and: setDate)
        // Set Entity
        try context.save()
    }
    
    //--------------------
    // Get
    //--------------------
    func getUser(with userId: String) throws -> UserObject {
        // Fetch ENtity
        let entity = try fetchEntity(with: userId)
        // Convert & Return
        return try convertToUser(with: entity)
    }
    
    //--------------------
    // Update
    //--------------------
    func updateUser(with dto: UserUpdateDTO) throws {
        // Fetch Entity
        let entity = try fetchEntity(with: dto.userId)
        // Update Check
        if checkUpdate(from: entity, to: dto) {
            try context.save()
        }
    }
    
    //--------------------
    // Delete
    //--------------------
    func deleteUser(with userId: String) throws {
        // Fetch Entity
        let entity = try fetchEntity(with: userId)
        // Delete Data
        context.delete(entity)
        try context.save()
    }
}

//===============================
// MARK: - Support Function
//===============================
extension UserServicesCoredata{
    
    // Fetch User Entity
    private func fetchEntity(with userId: String) throws -> UserEntity {
        // parameter setting
        let fetchReq: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        // Request Query
        fetchReq.predicate = NSPredicate(format: "user_id == %@", userId)
        fetchReq.fetchLimit = 1
        
        guard let entity = try context.fetch(fetchReq).first else {
            throw UserErrorCD.UnexpectedFetchError
        }
        return entity
    }
    
    // Set Entity
    private func createEntity(with object: UserObject, and setDate: Date) {
        let entity = UserEntity(context: context)
        
        entity.user_id = object.user_id
        entity.user_email = object.user_email
        entity.user_name = object.user_name
        entity.user_social_type = object.user_social_type
        entity.user_status = object.user_status
        entity.user_created_at = setDate
        entity.user_login_at = setDate
        entity.user_updated_at = setDate
    }
    
    // Convert: to Object
    private func convertToUser(with entity: UserEntity) throws -> UserObject {
        guard let data = UserObject(userEntity: entity) else {
            throw UserErrorCD.UnexpectedConvertError
        }
        return data
    }
    
    // Update
    private func checkUpdate(from origin: UserEntity, to updated: UserUpdateDTO) -> Bool {
        var isUpdated = false
        
        if let newEmail = updated.newEmail {
            isUpdated = util.updateFieldIfNeeded(&origin.user_email, newValue: newEmail) || isUpdated
        }
        if let newNickName = updated.newNickName {
            isUpdated = util.updateFieldIfNeeded(&origin.user_name, newValue: newNickName) || isUpdated
        }
        if let newUpdateAt = updated.newUpdateAt {
            isUpdated = util.updateFieldIfNeeded(&origin.user_updated_at, newValue: newUpdateAt) || isUpdated
        }
        if let newLoginAt = updated.newLoginAt {
            isUpdated = util.updateFieldIfNeeded(&origin.user_login_at, newValue: newLoginAt) || isUpdated
        }
        return isUpdated
    }
}

//===============================
// MARK: - Exception
//===============================
enum UserErrorCD: LocalizedError {
    case UnexpectedFetchError
    case UnexpectedConvertError
    case UserRetrievalByIdentifierFailed
    
    var errorDescription: String?{
        switch self {
        case .UnexpectedFetchError:
            return "Coredata: There was an unexpected error while Fetch 'User' details"
        case .UnexpectedConvertError:
            return "Coredata: There was an unexpected error while Convert 'User' details"
        case .UserRetrievalByIdentifierFailed:
            return "CoreData: Unable to retrieve 'User' data using the provided identifier."
        }
    }
}
