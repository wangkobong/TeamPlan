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
    // CoreData
    var persistentContainer: NSPersistentContainer
    
    // StoreType Setting
    init(storeType: NSPersistentStore.StoreType){
        persistentContainer = NSPersistentContainer(name: "Coredata")
        
        let desc = NSPersistentStoreDescription()
        desc.type = storeType.rawValue
        persistentContainer.persistentStoreDescriptions = [desc]
        
        persistentContainer.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            } else {
                print("Succcessfully Load CoreData : \(storeDescription.description)")
            }
        })
    }
    
    // Container Handler
    lazy var managedObjectContext: NSManagedObjectContext = {
        return persistentContainer.viewContext
    }()
    
    //================================
    // MARK: - Get User
    //================================
    func getUserCoredata(identifier: String) async -> UserObject {
        
        // parameter setting
        let context: NSManagedObjectContext = managedObjectContext
        let fetchReq: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        
        // Request Query
        fetchReq.predicate = NSPredicate(format: "user_id == %@", identifier)
        fetchReq.fetchLimit = 1
        
        do{
            let reqUser = try context.fetch(fetchReq)
            return UserObject(userEntity: reqUser.first!)
        } catch let error as NSError {
            let errorMessage = "Failed to get User by identifier"
            print("Failed to get User by identifier: \(identifier) \n \(error)")
            return UserObject(error: errorMessage)
        }
    }

    //================================
    // MARK: - Set User
    //================================
    
    func setUserCoredata(userObject: UserObject) async {
        let user = UserEntity(context: managedObjectContext)
        
        user.user_id = userObject.user_id
        user.user_fb_id = userObject.user_fb_id
        user.user_email = userObject.user_email
        user.user_name = userObject.user_name
        user.user_social_type = userObject.user_social_type
        user.user_status = userObject.user_status.rawValue
        user.user_created_at = userObject.user_created_at
        user.user_login_at = userObject.user_login_at
        user.user_updated_at = userObject.user_updated_at
        
        do{
            try managedObjectContext.save()
            print("Successfully Saved User Data")
        } catch {
            print("Failed to Save User Data: \(error)")
        }
    }
    
    //================================
    // MARK: - Update User
    //================================
    
    
    //================================
    // MARK: - Delete User
    //================================
    
}


