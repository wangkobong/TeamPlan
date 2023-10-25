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
    // MARK: - CoreData Setting
    //================================
    let cd = CoreDataManager.shared
    var context: NSManagedObjectContext {
        return cd.context
    }
    
    //================================
    // MARK: - Get User
    //================================
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
                return result(.failure(UserServiceCDError.UserRetrievalByIdentifierFailed))
            }
            return result(.success(UserObject(userEntity: userEntity)))
            
        // Eception Handling: Internal Error (Coredata)
        } catch {
            return result(.failure(UserServiceCDError.UnexpectedGetError))
        }
    }
    
    //================================
    // MARK: - Set User
    //================================
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
            return result(.failure(UserServiceCDError.UnexpectedSetError))
        }
    }
    
    //================================
    // MARK: - Update User
    //================================
    
    
    //================================
    // MARK: - Delete User
    //================================
}

//===============================
// MARK: - Exception
//===============================
enum UserServiceCDError: LocalizedError {
    case UserRetrievalByIdentifierFailed
    case UnexpectedSetError
    case UnexpectedGetError
    
    var errorDescription: String?{
        switch self {
        case .UserRetrievalByIdentifierFailed:
            return "CoreData: Unable to retrieve 'User' data using the provided identifier."
        case .UnexpectedSetError:
            return "Coredata: There was an unexpected error while Set 'User' details"
        case .UnexpectedGetError:
            return "Coredata: There was an unexpected error while Get 'User' details"
        }
    }
}


