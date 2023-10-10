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
    let cd = CoreDataManager.shared
    var context: NSManagedObjectContext {
        return cd.context
    }
    
    //================================
    // MARK: - Get Project
    //================================
    func getProjectCoredata() async -> [ProjectObject] {
        
        // parameter setting
        let fetchReq: NSFetchRequest<ProjectEntity> = ProjectEntity.fetchRequest()
        
        do{
            let projectEntities = try context.fetch(fetchReq)
            return projectEntities.map{ ProjectObject(projectEntity: $0 )}
        } catch {
            print("Failed to fetch projects: \(error)")
            return []
        }
    }
}
