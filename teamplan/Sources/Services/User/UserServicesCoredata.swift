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
    func getUserCoredata(identifier: String,
                         result: @escaping(Result<UserObject, Error>) -> Void) {
        
        // parameter setting
        let fetchReq: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        
        // Request Query
        fetchReq.predicate = NSPredicate(format: "user_id == %@", identifier)
        fetchReq.fetchLimit = 1
        
        do{
            let fetchUser = try context.fetch(fetchReq)
            
            // Exception Handling: Identifier
            guard let reqUser = fetchUser.first else {
                return result(.failure(UserServiceCDError.IdentifierFetchFailed))
            }
            return result(.success(UserObject(userEntity: reqUser)))
            
            // Eception Handling: Unknown
        } catch {
            return result(.failure(UserServiceCDError.GetFailed))
        }
    }
    
    //================================
    // MARK: - Set User
    //================================
    func setUserCoredata(userObject: UserObject,
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
            return result(.failure(UserServiceCDError.SetFailed))
        }
    }
    
    //================================
    // MARK: - Update User
    //================================
    
    
    //================================
    // MARK: - Delete User
    //================================
    
    
    //===============================
    // MARK: - Exception
    //===============================
    enum UserServiceCDError: LocalizedError {
        case IdentifierFetchFailed
        case SetFailed
        case GetFailed
        
        var errorDescription: String?{
            switch self {
            case .IdentifierFetchFailed:
                return "Failed to Fetch User by identifier"
            case .SetFailed:
                return "Failed to Set User Data at CoreData"
            case .GetFailed:
                return "Failed to Get User for Unknown reason"
            }
        }
    }
}


