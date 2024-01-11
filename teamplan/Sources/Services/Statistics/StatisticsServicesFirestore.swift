//
//  StatisticsServicesFirestore.swift
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
final class StatisticsServicesFirestore{
    
    //--------------------
    // Parameter
    //--------------------
    let util = Utilities()
    let fs = Firestore.firestore()
    
    //--------------------
    // Set
    //--------------------
    func setStatistics(with stat: StatisticsObject) async throws {
        // Search & Set Data
        let collection = fetchCollection()
        try await collection.addDocument(data: stat.toDictionary())
    }
    
    //--------------------
    // Get
    //--------------------
    func getStatistics(from userId: String) async throws -> StatisticsObject {
        // Fetch Data
        let docs = try await fetchDocs(with: userId)
        // Convert & Return
        return try convertToStat(with: docs.data())
    }
    
    //--------------------
    // Update
    //--------------------
    func updateStatistics(with updatedStat: StatisticsObject) async throws {
        // Fetch Data
        let docs = try await fetchDocs(with: updatedStat.stat_user_id)
        //Update Data
        try await docs.reference.updateData(updatedStat.toDictionary())
    }
    
    //--------------------
    // Delete
    //--------------------
    func deleteStatistics(with userId: String) async throws {
        // Fetch Data
        let docs = try await fetchDocs(with: userId)
        // Delete Data
        try await docs.reference.delete()
    }
}

//================================
// MARK: - Support Function
//================================
extension StatisticsServicesFirestore{
    
    // Fetch: Collection
    private func fetchCollection() -> CollectionReference {
        return fs.collection("Stat")
    }
    
    // Fetch: Document
    private func fetchDocs(with userId: String) async throws -> QueryDocumentSnapshot {
        // fetch reference
        let docsRef = try await fetchCollection()
            .whereField("stat_user_id", isEqualTo: userId)
            .getDocuments()
        
        // convert & return
        guard let docs = docsRef.documents.first else {
            throw StatErrorFS.UnexpectedSearchError
        }
        return docs
    }
    
    // Convert: to Object
    private func convertToStat(with data: [String:Any]) throws -> StatisticsObject {
        guard let stat = StatisticsObject(with: data) else {
            throw StatErrorFS.UnexpectedConvertError
        }
        return stat
    }
}

//================================
// MARK: - Exception
//================================
enum StatErrorFS: LocalizedError {
    case UnexpectedConvertError
    case UnexpectedSearchError
    
    var errorDescription: String? {
        switch self {
        case .UnexpectedSearchError:
            return "Firestore: There was an unexpected error while Search 'Statistics' details"
        case .UnexpectedConvertError:
            return "Firestore: There was an unexpected error while Convert 'Statistics' details"
        }
    }
}
