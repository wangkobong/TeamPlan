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
    func getProjectCoredata(identifier: String,
                            result: @escaping(Result<[ProjectObject], Error>) -> Void) {
        
        // parameter setting
        let fetchReq: NSFetchRequest<ProjectEntity> = ProjectEntity.fetchRequest()
        
        // Request Query
        fetchReq.predicate = NSPredicate(format: "proj_user_id == %@", identifier)
        
        do {
            let fetchProj = try context.fetch(fetchReq)
            
            // Exception Handling: Identifier
            if fetchProj.isEmpty {
                return result(.failure(ProjCDError.IdentifierFetchFailed))
            }
            
            // extract projects
            let reqProjects = fetchProj.map { ProjectObject(projectEntity: $0) }
            return result(.success(reqProjects))
            
        // Eception Handling: Unknown
        } catch {
            return result(.failure(ProjCDError.GetFailed))
        }
    }
    
    //===============================
    // MARK: - Exception
    //===============================
    enum ProjCDError: LocalizedError {
        case IdentifierFetchFailed
        case SetFailed
        case GetFailed
        
        var errorDescription: String?{
            switch self {
            case .IdentifierFetchFailed:
                return "Failed to Fetch Project by identifier"
            case .SetFailed:
                return "Failed to Set Project at CoreData"
            case .GetFailed:
                return "Failed to Get Project for Unknown reason"
            }
        }
    }
}
