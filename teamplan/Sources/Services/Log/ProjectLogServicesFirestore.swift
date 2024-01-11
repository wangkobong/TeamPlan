//
//  ProjectLogServicesFirestore.swift
//  teamplan
//
//  Created by 주찬혁 on 1/5/24.
//  Copyright © 2024 team1os. All rights reserved.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

//================================
// MARK: - Main Function
//================================
final class ProjectLogServicesFirestore{
    
    //--------------------
    // Parameter
    //--------------------
    let fs = Firestore.firestore()
    
    //--------------------
    // Set
    //--------------------
    func setLog(with log: ProjectLog) async throws {
        // Search & Set
        let collection = fetchCollection()
        try await collection.addDocument(data: log.toDictionary())
    }
    
    //--------------------
    // Get
    //--------------------
    // Single
    func getLog(with projectId: Int, by userId: String) async throws -> ProjectLog {
        // Fetch Document
        let docs = try await fetchDocument(with: projectId, by: userId)
        // Convert & Return
        return try convertToLog(with: docs.data())
    }
    
    // List
    func getLogList(with userId: String) async throws -> [ProjectLog] {
        // Fetch Documents
        let docsList = try await fetchDocuments(with: userId)
        // Convert & Return
        return try docsList.map { try convertToLog(with: $0.data()) }
        
    }
    
    //--------------------
    // Update
    //--------------------
    func updateLog(with updated: ProjectLog) async throws {
        // Fetch Document
        let docs = try await fetchDocument(with: updated.projectId, by: updated.userId)
        // Apply Update
        try await docs.reference.updateData(updated.toDictionary())
    }
    
    //--------------------
    // Delete
    //--------------------
    func deleteLog(with projectId: Int, by userId: String) async throws {
        // Fetch Document
        let docs = try await fetchDocument(with: projectId, by: userId)
        // Delete Document
        try await docs.reference.delete()
    }
    
}

//================================
// MARK: - Support Function
//================================
extension ProjectLogServicesFirestore{
    
    // fetch collection
    private func fetchCollection() -> CollectionReference {
        return fs.collection("ProjectLog")
    }
    
    // fetch document
    private func fetchDocument(with projectId: Int, by userId: String) async throws -> QueryDocumentSnapshot {
        // Fetch Reference
        let docsRef = try await fetchCollection()
            .whereField("log_user_id", isEqualTo: userId)
            .whereField("log_project_id", isEqualTo: projectId)
            .getDocuments()
        // Check & Return
        guard let docs = docsRef.documents.first else {
            throw ProjectLogErrorFS.UnexpectedFetchError
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
    private func convertToLog(with data: [String : Any]) throws -> ProjectLog {
        guard let log = ProjectLog(firestoreData: data) else {
            throw ProjectLogErrorFS.UnexpectedConvertError
        }
        return log
    }
}

//================================
// MARK: - Exception
//================================
enum ProjectLogErrorFS: LocalizedError {
    case UnexpectedFetchError
    case UnexpectedConvertError
    case InternalError
    
    var errorDescription: String?{
        switch self {
        case .UnexpectedFetchError:
            return "Firestore: There was an unexpected error while Fetch 'ProjectLog' Documents"
        case .UnexpectedConvertError:
            return "Firestore: There was an unexpected error while Convert 'ProjectLog' details"
        case .InternalError:
            return "Firestore: Internal Error Occurred while process 'ProjectLog' details"
        }
    }
}
