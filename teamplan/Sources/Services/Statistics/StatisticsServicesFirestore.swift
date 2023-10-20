//
//  StatisticsServicesFirestore.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/10/20.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation
import FirebaseFirestore

final class StatisticsServicesFirestore{
    
    // Firestore setting
    let fs = Firestore.firestore()
    
    //================================
    // MARK: - Set Statistics
    //================================
    func setStatisticsFS(reqStat: StatisticsObject,
                         result: @escaping(Result<String, Error>) -> Void) {
        
        // Target Table
        let collectionRef = fs.collection("Stat")
        
        // Add Statistics
        collectionRef.addDocument(data: reqStat.toDictionary()){ error in
            
            // Exception Handling: Firestore
            if let error = error {
                result(.failure(error))
            } else {
                result(.success("Successfully set Statistics at Firestore"))
            }
        }
    }
    
    //================================
    // MARK: - Update Statistics
    //================================
    
}
