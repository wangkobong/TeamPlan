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
    func setUser(reqUser: UserObject) async throws {
        do{
            // Set User
            setUserEntity(from: reqUser)
            
            // Store User
            try context.save()
        } catch {
            print("(CoreData) Error Set User : \(error)")
            throw UserErrorCD.UnexpectedSetError
        }
    }
    
    //##### Result #####
    func setUser(reqUser: UserObject,
                         result: @escaping(Result<String, Error>) -> Void) {
        do{
            // Set User
            setUserEntity(from: reqUser)
            
            // Store User
            try context.save()
            return result(.success("Successfully set User Data at CoreData"))
        } catch {
            print("(CoreData) Error Set User : \(error)")
            return result(.failure(UserErrorCD.UnexpectedSetError))
        }
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
    //##### Result #####
    func getUser(identifier: String,
                         result: @escaping(Result<UserObject, Error>) -> Void) {
        
        // parameter setting
        let fetchReq: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        
        // Request Query
        fetchReq.predicate = NSPredicate(format: "user_id == %@", identifier)
        fetchReq.fetchLimit = 1
        
        // Search User
        do{
            guard let userEntity = try context.fetch(fetchReq).first else {
                // Exception Handling: Identifier
                return result(.failure(UserErrorCD.UserRetrievalByIdentifierFailed))
            }
            guard let userData = UserObject(userEntity: userEntity) else {
                // Exception Handling: Fetch Error
                return result(.failure(UserErrorCD.UnexpectedFetchError))
            }
            return result(.success(userData))
            
        // Exception Handling: Internal Error (Coredata)
        } catch {
            print("(CoreData) Error Get User : \(error)")
            return result(.failure(UserErrorCD.UnexpectedGetError))
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
                throw UserErrorCD.UserRetrievalByIdentifierFailed
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
            print("(CoreData) Error Update User : \(error)")
            throw UserErrorCD.UnexpectedUpdateError
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
                throw UserErrorCD.UserRetrievalByIdentifierFailed
            }
            // Delete User
            self.context.delete(userEntity)
            try self.context.save()
            
        } catch {
            print("(CoreData) Error Delete User : \(error)")
            throw UserErrorCD.UnexpectedDeleteError
        }
    }
}

//===============================
// MARK: - Exception
//===============================
enum UserErrorCD: LocalizedError {
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

