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
    // MARK: - Get User: Home
    // return: name
    //================================
    

    //================================
    // MARK: - Get User: MyPage
    // return: email, socialType
    //================================
    
    
    //================================
    // MARK: - Set User: SignUp
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
    // MARK: - Update User: MyPage
    //================================
    
    
    //================================
    // MARK: - Delete User: MyPage
    //================================
    
}


