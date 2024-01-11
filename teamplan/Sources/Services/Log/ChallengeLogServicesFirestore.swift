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

//================================
// MARK: - Main Function
//================================
final class ChallengeLogServicesFirestore{
    
    //--------------------
    // Parameter
    //--------------------
    let fs = Firestore.firestore()
    
    //--------------------
    // Set
    //--------------------
    func setLog(with log: ChallengeLog) async throws {
        let collectionRef = fs.collection("ChallengeLog")
        try await collectionRef.addDocument(data: log.toDictionary())
    }
    
    //--------------------
    // Get
    //--------------------
    // Single
    func getLog(with userId: String, and logId: Int) async throws -> ChallengeLog {
        // fetch doc
        let docs = try await fetchDocument(with: userId, and: logId)
        // convert & return
        return try convertToLog(with: docs.data())
    }
    
    // List
    func getLogList(with userId: String) async throws -> [ChallengeLog] {
        // fetch docs
        let docsList = try await fetchDocuments(with: userId)
        // convert & return
        return try docsList.compactMap { doc in
            try convertToLog(with: doc.data())
        }
    }
    
    //--------------------
    // Update
    //--------------------
    func updateLog(with updated: ChallengeLog) async throws {
        // fetch doc
        let docs = try await fetchDocument(with: updated.log_user_id, and: updated.log_id)
        // apply update
        try await docs.reference.updateData(updated.toDictionary())
    }
    
    //--------------------
    // Delete
    //--------------------
    // Single
    func deleteLog(with userId: String, and logId: Int) async throws {
        // fetch doc
        let docs = try await fetchDocument(with: userId, and: logId)
        // delete doc
        try await docs.reference.delete()
    }
    
    // List
    func deleteLogList(with userId: String) async throws {
        // fetch docs
        let docsList = try await fetchDocuments(with: userId)
        // delete docs
        for docs in docsList {
            try await docs.reference.delete()
        }
    }
}

//================================
// MARK: - Support Function
//================================
extension ChallengeLogServicesFirestore{
    
    // Fetch Collection
    private func fetchCollection() -> CollectionReference {
        return fs.collection("ChallengeLog")
    }
    
    // Fetch Document
    private func fetchDocument(with userId: String, and logId: Int) async throws -> QueryDocumentSnapshot {
        // fetch reference
        let docsRef = try await fetchCollection()
            .whereField("log_user_id", isEqualTo: userId)
            .whereField("log_id", isEqualTo: logId)
            .getDocuments()
        // check & return
        guard let docs = docsRef.documents.first else {
            throw ChallengeLogErrorFS.UnexpectedFetchError
        }
        return docs
    }
    
    // Fetch Documents
    private func fetchDocuments(with userId: String) async throws -> [QueryDocumentSnapshot] {
        // fetch reference
        let docsRef = try await fetchCollection()
            .whereField("log_user_id", isEqualTo: userId)
            .getDocuments()
        // check & return
        return docsRef.documents
    }
    
    // Convert: to Object
    private func convertToLog(with data: [String : Any]) throws -> ChallengeLog {
        guard let log = ChallengeLog(from: data) else {
            throw ChallengeLogErrorFS.UnexpectedConvertError
        }
        return log
    }
}

//================================
// MARK: - Exception
//================================
enum ChallengeLogErrorFS: LocalizedError {
    case UnexpectedFetchError
    case UnexpectedConvertError
    
    var errorDescription: String?{
        switch self {
        case .UnexpectedFetchError:
            return "Firestore: There was an unexpected error while Fetch 'ChallengeLog' Documents"
        case .UnexpectedConvertError:
            return "Firestore: There was an unexpected error while Convert 'ChallengeLog' details"
        }
    }
}
