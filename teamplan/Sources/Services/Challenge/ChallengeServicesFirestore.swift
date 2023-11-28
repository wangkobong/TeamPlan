//
//  ChallengeServicesFirestore.swift
//  teamplan
//
//  Created by 주찬혁 on 11/27/23.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

final class ChallengeServicesFirestore{
    
    //================================
    // MARK: - Parameter Setting
    //================================
    let util = Utilities()
    let fs = Firestore.firestore()
    
    //================================
    // MARK: - Get Challenges
    //================================
    func getChallenges() async throws -> [ChallengeObject] {
        
        // Search Data
        let collectionRef = fs.collection("Challenge")
        let docsRef = try await collectionRef.getDocuments()
        
        // Convert to Object
        let challenges = docsRef.documents.compactMap { docs -> ChallengeObject? in
            return ChallengeObject(challengeData: docs.data())
        }
        // Exception Handling : Fetch Error
        if challenges.count != docsRef.documents.count {
            throw ChallengeErrorFS.InternalError
        }
        return challenges
    }
}

//================================
// MARK: - Exception
//================================
enum ChallengeErrorFS: LocalizedError {
    case InternalError
    
    var errorDescription: String?{
        switch self {
        case .InternalError:
            return "Firestore: Internal Error Occurred while process 'User' details"
        }
    }
}
