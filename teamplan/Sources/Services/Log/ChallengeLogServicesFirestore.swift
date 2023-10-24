//
//  ChallengeLogServicesFirestore.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/10/20.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation
import FirebaseFirestore

final class ChallengeLogServicesFirestore{
    
    // Firestore setting
    let fs = Firestore.firestore()
    
    //================================
    // MARK: - Set ChallengeLog
    //================================
    func setChallengeLogFS(reqLog: ChallengeLog,
                           result: @escaping(Result<String, Error>) -> Void) {
        
        // Target Table
        let collectionRef = fs.collection("ChallengeLog")
        
        // Add ChallengeLog
        collectionRef.addDocument(data: reqLog.toDictionary()){ error in
            
            // Exception Handling: Firestore
            if let error = error {
                result(.failure(error))
                
            } else {
                result(.success("Successfully set ChallengeLog at Firestore"))
            }
        }
    }
}
