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

//================================
// MARK: - Main Function
//================================
final class AccessLogServicesFirestore{

    //--------------------
    // Parameter
    //--------------------
    let fs = Firestore.firestore()
    
    //--------------------
    // Set
    //--------------------
    func setLog(with log: AccessLog) async throws {
        
        // Search & Set Data
        let collectionRef = fs.collection("AccessLog")
        try await collectionRef.addDocument(data: log.toDictionary())
    }
    
    //--------------------
    // Get
    //--------------------
    // Single
    func getLog(with userId: String, and logId: Int) async throws -> AccessLog {
        // Fetch Document
        let docs = try await fetchDocument(with: userId, and: logId)
        // Convert & Return
        return try convertToLog(with: docs.data())
    }
    
    // List
    func getLogList(with userId: String) async throws -> [AccessLog] {
        // Fetch Documents
        let docsList = try await fetchDocuments(with: userId)
        // Convert & Return
        return try docsList.compactMap { doc in
            try convertToLog(with: doc.data())
        }
    }
    
    //--------------------
    // Update
    //--------------------
    func updateLog(to updated: AccessLog) async throws {
        // Fetch Document
        let docs = try await fetchDocument(with: updated.log_user_id, and: updated.log_id)
        // Apply Update
        try await docs.reference.updateData(updated.toDictionary())
    }
    
    //--------------------
    // Delete
    //--------------------
    // Single
    func deleteLog(with userId: String, and logId: Int) async throws {
        // Fetch Document
        let docs = try await fetchDocument(with: userId, and: logId)
        // Delete Document
        try await docs.reference.delete()
    }
    
    // List
    func deleteLogList(with userId: String) async throws {
        // Fetch Documents
        let docsList = try await fetchDocuments(with: userId)
        // Delete Documents
        for docs in docsList {
            try await docs.reference.delete()
        }
    }
}

//================================
// MARK: - Main Function
//================================
extension AccessLogServicesFirestore {
    
    // fetch collection
    private func fetchCollection() -> CollectionReference {
        return fs.collection("AccessLog")
    }
    
    // fetch document
    private func fetchDocument(with userId: String, and logId: Int) async throws -> QueryDocumentSnapshot {
        // Fetch Reference
        let docsRef = try await fetchCollection()
            .whereField("log_user_id", isEqualTo: userId)
            .whereField("log_id", isEqualTo: logId)
            .getDocuments()
        // Check & Return
        guard let docs = docsRef.documents.first else {
            throw AccessLogErrorFS.UnexpectedFetchError
        }
        return docs
    }
    
    // fetch documents
    private func fetchDocuments(with userId: String) async throws -> [QueryDocumentSnapshot] {
        // Fetch Reference
        let docsRef = try await fetchCollection()
            .whereField("log_user_id", isEqualTo: userId)
            .getDocuments()
        // Check & Return
        return docsRef.documents
    }
    
    // Convert: to Object
    private func convertToLog(with data: [String : Any]) throws -> AccessLog {
        guard let log = AccessLog(data: data) else {
            throw AccessLogErrorFS.UnexpectedConvertError
        }
        return log
    }
}


//================================
// MARK: - Exception
//================================
enum AccessLogErrorFS: LocalizedError {
    case UnexpectedFetchError
    case UnexpectedConvertError
    
    var errorDescription: String? {
        switch self {
        case .UnexpectedFetchError:
            return "Firestore: There was an unexpected error while Fetch 'Accesslog' details"
        case .UnexpectedConvertError:
            return "Firestore: There was an unexpected error while Convert 'Accesslog' details"
        }
    }
}
