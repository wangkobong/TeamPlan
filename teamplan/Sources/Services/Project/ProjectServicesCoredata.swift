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
    func getProjects(from identifier: String) throws -> [ProjectObject] {
        // parameter setting
        let fetchReq: NSFetchRequest<ProjectEntity> = ProjectEntity.fetchRequest()
        
        // Request Query
        fetchReq.predicate = NSPredicate(format: "proj_user_id == %@", identifier)
        
        do {
            let reqProj = try context.fetch(fetchReq)
            
            // Exception Handling: Identifier
            guard !reqProj.isEmpty else {
                throw ProjectErrorCD.StatRetrievalByIdentifierFailed
            }
            
            return reqProj.map { ProjectObject(projectEntity: $0) }
        } catch {
            print("(CoreData) Error Get Project : \(error)")
            throw ProjectErrorCD.UnexpectedGetError
        }
    }
}

//===============================
// MARK: - Exception
//===============================
enum ProjectErrorCD: LocalizedError {
    case UnexpectedSetError
    case UnexpectedGetError
    case UnexpectedUpdateError
    case UnexpectedDeleteError
    case StatRetrievalByIdentifierFailed
    case UnexpectedFetchError
    case UnexpectedConvertError
    
    var errorDescription: String?{
        switch self {
        case .UnexpectedSetError:
            return "Coredata: There was an unexpected error while Set 'Project' details"
        case .UnexpectedGetError:
            return "Coredata: There was an unexpected error while Get 'Project' details"
        case .UnexpectedUpdateError:
            return "Coredata: There was an unexpected error while Update 'Project' details"
        case .UnexpectedDeleteError:
            return "Coredata: There was an unexpected error while Delete 'Project' details"
        case .StatRetrievalByIdentifierFailed:
            return "Coredata: Unable to retrieve 'Project' data using the provided identifier."
        case .UnexpectedFetchError:
            return "Coredata: There was an unexpected error while Fetch 'Project' details"
        case .UnexpectedConvertError:
            return "Coredata: There was an unexpected error while Convert 'Project' details"
        }
    }
}
