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
    //##### Async/Await #####
    func setUser(reqUser: UserObject) async throws -> String {
        
        // Create New UserEntity
        let userEntity = UserEntity(context: context)
        
        userEntity.user_id = reqUser.user_id
        userEntity.user_fb_id = reqUser.user_fb_id
        userEntity.user_email = reqUser.user_email
        userEntity.user_name = reqUser.user_name
        userEntity.user_social_type = reqUser.user_social_type
        userEntity.user_status = reqUser.user_status
        userEntity.user_created_at = reqUser.user_created_at
        userEntity.user_login_at = reqUser.user_login_at
        userEntity.user_updated_at = reqUser.user_updated_at
        
        // Add User
        do{
            try context.save()
            return "Successfully set User Data at CoreData"
        } catch {
            print(error)
            throw UserCDError.UnexpectedSetError
        }
    }
    
    //##### Result #####
    func setUser(userObject: UserObject,
                         result: @escaping(Result<String, Error>) -> Void) {
        
        // Create New UserEntity
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
        
        do{
            try context.save()
            return result(.success("Successfully set User Data at CoreData"))
        } catch {
            print(error)
            return result(.failure(UserCDError.UnexpectedSetError))
        }
    }
    
    //================================
    // MARK: - Get User
    //================================
    //##### Result #####
    func getUser(identifier: String,
                         result: @escaping(Result<UserObject, Error>) -> Void) {
        
        // parameter setting
        let fetchReq: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        
        // Request Query
        fetchReq.predicate = NSPredicate(format: "user_id == %@", identifier)
        fetchReq.fetchLimit = 1
        
        do{
            // Exception Handling: Identifier
            guard let userEntity = try context.fetch(fetchReq).first else {
                return result(.failure(UserCDError.UserRetrievalByIdentifierFailed))
            }
            guard let userData = UserObject(userEntity: userEntity) else {
                return result(.failure(UserCDError.UnexpectedFetchError))
            }
            return result(.success(userData))
            
        // Eception Handling: Internal Error (Coredata)
        } catch {
            print(error)
            return result(.failure(UserCDError.UnexpectedGetError))
        }
    }
    
    //================================
    // MARK: - Update User
    //================================
    //##### Async/Await #####
    func updateUser(updatedUser: UserObject) async throws {
        
        // parameter setting
        let fetchReq: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        
        
        // Request Query
        fetchReq.predicate = NSPredicate(format: "user_id == %@", updatedUser.user_id)
        fetchReq.fetchLimit = 1
        
        do {
            // Search UserEntity
            guard let userEntity = try context.fetch(fetchReq).first else {
                
                // Exception Handling: Identifier
                throw UserCDError.UserRetrievalByIdentifierFailed
            }
            
            // Updated field Check
            var isUpdated = false
            isUpdated = util.updateFieldIfNeeded(&userEntity.user_fb_id, newValue: updatedUser.user_fb_id) || isUpdated
            isUpdated = util.updateFieldIfNeeded(&userEntity.user_name, newValue: updatedUser.user_name) || isUpdated
            isUpdated = util.updateFieldIfNeeded(&userEntity.user_status, newValue: updatedUser.user_status) || isUpdated
            isUpdated = util.updateFieldIfNeeded(&userEntity.user_login_at, newValue: updatedUser.user_login_at) || isUpdated
            isUpdated = util.updateFieldIfNeeded(&userEntity.user_updated_at, newValue: updatedUser.user_updated_at) || isUpdated
            
            // Update UserEntity
            if isUpdated {
                try context.save()
            }
            
        } catch {
            // Eception Handling: Internal Error (Coredata)
            print(error)
            throw UserCDError.UnexpectedUpdateError
        }
    }
    
    //================================
    // MARK: - Delete User
    //================================
    //##### Async/Await #####
    func deleteUser(identifier: String) async throws {
        
        // parameter setting
        let fetchReq: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        
        // Request Query
        fetchReq.predicate = NSPredicate(format: "user_id == %@", identifier)
        fetchReq.fetchLimit = 1
        
        do {
            // Search UserEntity
            guard let userEntity = try context.fetch(fetchReq).first else {
                
                // Exception Handling: Identifier
                throw UserCDError.UserRetrievalByIdentifierFailed
            }
            // Delete User
            self.context.delete(userEntity)
            try self.context.save()
            
        } catch {
            print(error)
            throw UserCDError.UnexpectedDeleteError
        }
    }
}

//===============================
// MARK: - Exception
//===============================
enum UserCDError: LocalizedError {
    case UnexpectedSetError
    case UnexpectedGetError
    case UnexpectedUpdateError
    case UnexpectedDeleteError
    case UnexpectedFetchError
    case UserRetrievalByIdentifierFailed
    
    var errorDescription: String?{
        switch self {
        case .UnexpectedSetError:
            return "Coredata: There was an unexpected error while Set 'User' details"
        case .UnexpectedGetError:
            return "Coredata: There was an unexpected error while Get 'User' details"
        case .UnexpectedUpdateError:
            return "Coredata: There was an unexpected error while Update 'User' details"
        case .UnexpectedDeleteError:
            return "Coredata: There was an unexpected error while Delete 'User' details"
        case .UnexpectedFetchError:
            return "Coredata: There was an unexpected error while Fetch 'User' details"
        case .UserRetrievalByIdentifierFailed:
            return "CoreData: Unable to retrieve 'User' data using the provided identifier."
        }
    }
}

