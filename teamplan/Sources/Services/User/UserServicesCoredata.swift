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
    // MARK: - Parameter Setting
    //================================
    let util = Utilities()
    let cd = CoreDataManager.shared
    var context: NSManagedObjectContext {
        return cd.context
    }
    
    //================================
    // MARK: - Set User
    //================================
    func setUser(reqUser: UserObject) throws {
        
        // Create Entity & Set Data
        setUserEntity(from: reqUser)
        try context.save()
    }
    // Support Function
    private func setUserEntity(from userObject: UserObject){
        let user = UserEntity(context: context)

        user.user_id = userObject.user_id
        user.user_fb_id = userObject.user_fb_id
        user.user_email = userObject.user_email
        user.user_name = userObject.user_name
        user.user_social_type = userObject.user_social_type
        user.user_status = userObject.user_status
        user.user_created_at = userObject.user_created_at
        user.user_login_at = userObject.user_login_at
        user.user_updated_at = userObject.user_updated_at
    }
    
    //================================
    // MARK: - Get User
    //================================
    func getUser(from userId: String) throws -> UserObject {
        
        // parameter setting
        let fetchReq: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        
        // Request Query
        fetchReq.predicate = NSPredicate(format: "user_id == %@", userId)
        fetchReq.fetchLimit = 1
        
        // Search Data
        guard let reqUser = try context.fetch(fetchReq).first else {
            throw UserErrorCD.UserRetrievalByIdentifierFailed
        }
        // Convert to Object & Get
        guard let userData = UserObject(userEntity: reqUser) else {
            throw UserErrorCD.UnexpectedConvertError
        }
        return userData
    }
    
    //================================
    // MARK: - Update User
    //================================
    func updateUser(updatedUser: UserObject) throws {
        
        // parameter setting
        let fetchReq: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        
        // Request Query
        fetchReq.predicate = NSPredicate(format: "user_id == %@", updatedUser.user_id)
        fetchReq.fetchLimit = 1
        
        // Search Data
        guard let reqUser = try context.fetch(fetchReq).first else {
            throw UserErrorCD.UserRetrievalByIdentifierFailed
        }
        // Update Data
        if checkUpdate(from: reqUser, to: updatedUser) {
            try context.save()
        }
    }
    // Support Function
    private func checkUpdate(from origin: UserEntity, to updated: UserObject) -> Bool {
        var isUpdated = false
        isUpdated = util.updateFieldIfNeeded(&origin.user_fb_id, newValue: updated.user_fb_id) || isUpdated
        isUpdated = util.updateFieldIfNeeded(&origin.user_name, newValue: updated.user_name) || isUpdated
        isUpdated = util.updateFieldIfNeeded(&origin.user_status, newValue: updated.user_status) || isUpdated
        isUpdated = util.updateFieldIfNeeded(&origin.user_login_at, newValue: updated.user_login_at) || isUpdated
        isUpdated = util.updateFieldIfNeeded(&origin.user_updated_at, newValue: updated.user_updated_at) || isUpdated
        return isUpdated
    }
    
    //================================
    // MARK: - Delete User
    //================================
    func deleteUser(identifier: String) throws {
        
        // parameter setting
        let fetchReq: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        
        // Request Query
        fetchReq.predicate = NSPredicate(format: "user_id == %@", identifier)
        fetchReq.fetchLimit = 1
        
        // Search Data
        guard let userEntity = try context.fetch(fetchReq).first else {
            throw UserErrorCD.UserRetrievalByIdentifierFailed
        }
        // Delete Data
        context.delete(userEntity)
        try context.save()
    }
}

//===============================
// MARK: - Exception
//===============================
enum UserErrorCD: LocalizedError {
    case UnexpectedConvertError
    case UserRetrievalByIdentifierFailed
    // Legacy Only
    case UnexpectedSetError
    case UnexpectedGetError
    case UnexpectedFetchError
    
    var errorDescription: String?{
        switch self {
        case .UnexpectedConvertError:
            return "Coredata: There was an unexpected error while Convert 'User' details"
        case .UserRetrievalByIdentifierFailed:
            return "CoreData: Unable to retrieve 'User' data using the provided identifier."
        // Legacy Only
        case .UnexpectedSetError:
            return "Coredata: There was an unexpected error while Set 'User' details"
        case .UnexpectedGetError:
            return "Coredata: There was an unexpected error while Get 'User' details"
        case .UnexpectedFetchError:
            return "Coredata: There was an unexpected error while Fetch 'User' details"
        }
    }
}
