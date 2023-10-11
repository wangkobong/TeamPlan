//
//  StatisticsServiceCoredata.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/10/10.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation
import CoreData

final class StatisticsServiceCoredata{
    
    //================================
    // MARK: - CoreData Setting
    //================================
    let cd = CoreDataManager.shared
    var context: NSManagedObjectContext {
        return cd.context
    }
    
    //================================
    // MARK: - Get Statistics
    //================================
    func getStatCoredata() -> StatisticsObject {
        
        let fetchReq: NSFetchRequest<StatisticsEntity> = StatisticsEntity.fetchRequest()
        
        do{
            let reqStat = try context.fetch(fetchReq)
            
            if let uniqueStat = reqStat.first {
                return StatisticsObject(statEntity: uniqueStat)
            } else {
                print("No Statistics Entity Found")
                return StatisticsObject(error: "No Statistics Entity Found")
            }
            
        } catch let error as NSError {
            print("Failed to get Statistics Info: \(error.localizedDescription)")
            return StatisticsObject(error: error.localizedDescription)
        }
    }
}
