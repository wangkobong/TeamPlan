//
//  ProjectServicesCoredata.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/08/25.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation
import CoreData

final class ProjectServicesCoredata{
    
    //================================
    // MARK: - CoreData Setting
    //================================
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
    // MARK: - Get Project: Home
    //================================
    func getProjectCoredata() async -> [ProjectHomeLocalResDTO] {
        
        let context: NSManagedObjectContext = managedObjectContext
        let fetchReq: NSFetchRequest<ProjectEntity> = ProjectEntity.fetchRequest()
        
        do{
            let projectEntities = try context.fetch(fetchReq)
            return projectEntities.map{ProjectHomeLocalResDTO(from: $0)}
        } catch {
            print("Failed to fetch projects: \(error)")
            return []
        }
    }
    
    //================================
    // MARK: - Dummy
    //================================
    func createDummyProject() -> [ProjectObject]{
        
        var projectAry: [ProjectObject] = []
        
        for i in 1...5{
            var todoAry: [TodoObject] = []
            
            // Struct Dummy Todo
            for j in 1...10 {
                let todo = TodoObject(
                    todo_id: Int64(i * 10 + j),
                    todo_desc: "Todo: \(j) for Project: \(i)",
                    todo_pinned: false,
                    todo_status: true,
                    todo_registed_at: Date(),
                    todo_changed_at: Date(),
                    todo_updated_at: Date()
                )
                todoAry.append(todo)
            }
            
            // Struct Dummy Project
            // add 1 weak for testing sort
            let projInterval = Double(i) * 60 * 60 * 24 * 7
            let project = ProjectObject(
                proj_id: Int64(i),
                proj_title: "Project: \(i)",
                proj_started_at: Date(),
                proj_deadline: Date().addingTimeInterval(projInterval),
                proj_finished: false,
                proj_todo: todoAry,
                proj_todo_registed: 10,
                proj_todo_finished: 0,
                proj_registed_at: Date(),
                proj_changed_at: Date(),
                proj_finished_at: Date()
            )
            projectAry.append(project)
        }
        return projectAry
    }
}
