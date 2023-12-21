//
//  AccessLogServicesFirestore.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/10/20.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

final class AccessLogServicesFirestore{

    //================================
    // MARK: - Parameter Setting
    //================================
    let fs = Firestore.firestore()
    
    //================================
    // MARK: - Set AccessLog
    //================================
    func setLog(with log: AccessLog) async throws {
        
        // Search & Set Data
        let collectionRef = fs.collection("AccessLog")
        try await collectionRef.addDocument(data: log.toDictionary())
    }
    
    //================================
    // MARK: - Get AccessLog
    //================================
    func getLog(with userId: String) async throws -> AccessLog {
        
        // Search Data
        let collectionRef = fs.collection("AccessLog")
        let docsRef = try await collectionRef.whereField("log_user_id", isEqualTo: userId).getDocuments()
        
        // Exception Handling : Search Error
        guard docsRef.documents.count == 1 else {
            if docsRef.documents.count > 1 {
                throw AccessLogErrorFS.MultipleAcclogFound
            } else {
                throw AccessLogErrorFS.InternalError
            }
        }
        
        // Convert to Log & Get
        let docs = docsRef.documents.first!
        guard let log = AccessLog(logData: docs.data()) else {
            throw AccessLogErrorFS.UnexpectedConvertError
        }
        return log
    }
    
    //================================
    // MARK: - Update AccessLog
    //================================
    func updateLog(to updatedLog: AccessLog) async throws {
        
        // Search Data
        let collectionRef = fs.collection("AccessLog")
        let docsRef = try await collectionRef.whereField("log_user_id", isEqualTo: updatedLog.log_user_id).getDocuments()
        
        // Exception Handling : Search Error
        guard docsRef.documents.count == 1 else {
            if docsRef.documents.count > 1 {
                throw AccessLogErrorFS.MultipleAcclogFound
            } else {
                throw AccessLogErrorFS.InternalError
            }
        }
        // Update Log
        let docs = docsRef.documents.first!
        try await docs.reference.updateData(updatedLog.toDictionary())
    }
    
    
    //================================
    // MARK: - Delete AccessLog
    //================================
    func deleteLog(with userId: String) async throws {
        
        // Search Data
        let collectionRef = fs.collection("AccessLog")
        let docsRef = try await collectionRef.whereField("log_user_id", isEqualTo: userId).getDocuments()
        
        // Exception Handling : Search Error
        guard docsRef.documents.count == 1 else {
            if docsRef.documents.count > 1 {
                throw AccessLogErrorFS.MultipleAcclogFound
            } else {
                throw AccessLogErrorFS.InternalError
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
enum AccessLogErrorFS: LocalizedError {
    case UnexpectedConvertError
    case AcclogRetrievalByIdentifierFailed
    case MultipleAcclogFound
    case InternalError
    
    var errorDescription: String? {
        switch self {
        case .UnexpectedConvertError:
            return "Firestore: There was an unexpected error while Convert 'Accesslog' details"
        case .AcclogRetrievalByIdentifierFailed:
            return "Firestore: Unable to retrieve 'Accesslog' data using the provided identifier."
        case .MultipleAcclogFound:
            return "Firestore: Multiple 'Accesslog' found. Expected only one."
        case .InternalError:
            return "Firestore: Internal Error Occurred while process 'Accesslog' details"
        }
    }
}
