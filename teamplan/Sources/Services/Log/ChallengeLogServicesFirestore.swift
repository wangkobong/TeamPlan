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
    //##### Async/Await #####
    func setLog(reqLog: ChallengeLog) async throws {
        
        // Target Table
        let collectionRef = fs.collection("ChallengeLog")
        
        do
        {
            // Set ChallengeLog
            try await collectionRef.addDocument(data: reqLog.toDictionary())
        } catch {
            print("(Firestore) Error Set ChallengeLog : \(error)")
            throw ChallengeLogErrorFS.UnexpectedSetError
        }
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
        
        // Convert Docs to Object
        let docs = docsRef.documents.first!
        guard let log = ChallengeLog(challengeData: docs.data()) else {
            throw ChallengeLogErrorFS.UnexpectedConvertError
        }
        return log
    }
    
    //================================
    // MARK: - Update ChallengeLog
    //================================
    func updateLog(from userId: String, to updatedLog: ChallengeLog) async throws {
        
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
        
        let docs = docsRef.documents.first!
        try await docs.reference.updateData(updatedLog.toDictionary())
    }
    
    //================================
    // MARK: - Delete ChallengeLog
    //================================
    //##### Async/Await #####
    func deleteChallengeLog(identifier: String) async throws {
        
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
        
        let docs = docsRef.documents.first!
        try await docs.reference.delete()
    }
}

//================================
// MARK: - Exception
//================================
enum ChallengeLogErrorFS: LocalizedError {
    case UnexpectedSetError
    case UnexpectedGetError
    case UnexpectedUpdateError
    case UnexpectedDeleteError
    case UnexpectedFetchError
    case UnexpectedConvertError
    case ChallengeLogRetrievalByIdentifierFailed
    case MultipleChallengeLogFound
    case InternalError
    
    var errorDescription: String?{
        switch self {
        case .UnexpectedSetError:
            return "Firestore: There was an unexpected error while Set 'ChallengeLog' details"
        case .UnexpectedGetError:
            return "Firestore: There was an unexpected error while Get 'ChallengeLog' details"
        case .UnexpectedUpdateError:
            return "Firestore: There was an unexpected error while Update 'ChallengeLog' details"
        case .UnexpectedDeleteError:
            return "Firestore: There was an unexpected error while Delete 'ChallengeLog' details"
        case .UnexpectedFetchError:
            return "Firestore: There was an unexpected error while Fetch 'ChallengeLog' details from DocumentReference"
        case .UnexpectedConvertError:
            return "Firestore: There was an unexpected error while Convert 'ChallengeLog' details"
        case .ChallengeLogRetrievalByIdentifierFailed:
            return "Firestore: Unable to retrieve 'ChallengeLog' data using the provided identifier."
        case .MultipleChallengeLogFound:
            return "Firestore: Multiple 'ChallengeLog' found. Expected only one."
        case .InternalError:
            return "Firestore: Internal Error Occurred while process 'ChallengeLog' details"
        }
    }
}
