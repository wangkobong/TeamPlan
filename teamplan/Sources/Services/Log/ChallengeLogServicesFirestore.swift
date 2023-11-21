//
//  ChallengeLogServicesFirestore.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/10/20.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

final class ChallengeLogServicesFirestore{
    
    //================================
    // MARK: - Parameter Setting
    //================================
    let fs = Firestore.firestore()
    
    //================================
    // MARK: - Set ChallengeLog
    //================================
    func setLog(reqLog: ChallengeLog) async throws {
        
        // Search & Set Data
        let collectionRef = fs.collection("ChallengeLog")
        try await collectionRef.addDocument(data: reqLog.toDictionary())
    }
    
    //================================
    // MARK: - Get ChallengeLog
    //================================
    func getLog(from userId: String) async throws -> ChallengeLog {
        
        // Search Table
        let collectionRef = fs.collection("ChallengeLog")
        let docsRef = try await collectionRef.whereField("log_user_id", isEqualTo: userId).getDocuments()
        
        // Exception Handling : Search Error
        guard docsRef.documents.count == 1 else {
            if docsRef.documents.count > 1 {
                throw ChallengeLogErrorFS.MultipleChallengeLogFound
            } else {
                throw ChallengeLogErrorFS.InternalError
            }
        }
        // Convert to Object & Get
        let docs = docsRef.documents.first!
        guard let log = ChallengeLog(challengeData: docs.data()) else {
            throw ChallengeLogErrorFS.UnexpectedConvertError
        }
        return log
    }
    
    //================================
    // MARK: - Update ChallengeLog
    //================================
    func updateLog(to updatedData: ChallengeLog) async throws {
        
        // Search Table
        let collectionRef = fs.collection("ChallengeLog")
        let docsRef = try await collectionRef.whereField("log_user_id", isEqualTo: updatedData.log_user_id).getDocuments()
        
        // Exception Handling : Search Error
        guard docsRef.documents.count == 1 else {
            if docsRef.documents.count > 1 {
                throw ChallengeLogErrorFS.MultipleChallengeLogFound
            } else {
                throw ChallengeLogErrorFS.InternalError
            }
        }
        // Update Documents
        let docs = docsRef.documents.first!
        try await docs.reference.updateData(updatedData.toDictionary())
    }
    
    //================================
    // MARK: - Delete ChallengeLog
    //================================
    func deleteLog(identifier: String) async throws {
        
        // Target Table
        let collectionRef = fs.collection("ChallengeLog")
        let docsRef = try await collectionRef.whereField("log_user_id", isEqualTo: identifier).getDocuments()
        
        // Exception Handling : Search Error
        guard docsRef.documents.count == 1 else {
            if docsRef.documents.count > 1 {
                throw ChallengeLogErrorFS.MultipleChallengeLogFound
            } else {
                throw ChallengeLogErrorFS.InternalError
            }
        }
        // Delete Documents
        let docs = docsRef.documents.first!
        try await docs.reference.delete()
    }
}

//================================
// MARK: - Exception
//================================
enum ChallengeLogErrorFS: LocalizedError {
    case UnexpectedConvertError
    case MultipleChallengeLogFound
    case InternalError
    
    var errorDescription: String?{
        switch self {
        case .UnexpectedConvertError:
            return "Firestore: There was an unexpected error while Convert 'ChallengeLog' details"
        case .MultipleChallengeLogFound:
            return "Firestore: Multiple 'ChallengeLog' found. Expected only one."
        case .InternalError:
            return "Firestore: Internal Error Occurred while process 'ChallengeLog' details"
        }
    }
}
