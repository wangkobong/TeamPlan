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

final class StatisticsServicesFirestore{
    
    //================================
    // MARK: - Parameter Setting
    //================================
    let util = Utilities()
    let fs = Firestore.firestore()
    
    //================================
    // MARK: - Set Statistics
    //================================
    func setStatistics(with object: StatisticsObject) async throws {
        
        // Search & Set Data
        let collectionRef = fs.collection("Stat")
        try await collectionRef.addDocument(data: object.toDictionary())
    }
    
    //================================
    // MARK: - Get Statistics
    //================================
    func getStatistics(from userId: String) async throws -> StatisticsObject {
        
        // Fetch Data
        let docs = try await fetchDocs(with: userId)
        // Convert to Object
        guard let object = StatisticsObject(statData: docs.data()) else {
            throw StatErrorFS.UnexpectedConvertError
        }
        return object
    }

    //================================
    // MARK: - Update Statistics
    //================================
    // Object
    func updateStatistics(with object: StatisticsObject) async throws {
        
        // Fetch Data
        let docs = try await fetchDocs(with: object.stat_user_id)
        // Update Data
        try await docs.reference.updateData(object.toDictionary())
    }
    
    // DTO
    func updateStatistics(with dto: StatUpdateDTO) async throws {
        
        // Fetch Data
        let docs = try await fetchDocs(with: dto.stat_user_id)
        //Update Data
        try await docs.reference.updateData(dto.toDictionary())
    }
    
    //================================
    // MARK: - Delete Statistics
    //================================
    func deleteStatistics(with userId: String) async throws {
        
        // Fetch Data
        let docs = try await fetchDocs(with: userId)
        // Delete Data
        try await docs.reference.delete()
    }
    
    //================================
    // MARK: - Support Function
    //================================
    private func fetchDocs(with userId: String) async throws -> QueryDocumentSnapshot {
        
        // Search Data
        let collectionRef = fs.collection("Stat")
        let docsRef = try await collectionRef.whereField("stat_user_id", isEqualTo: userId).getDocuments()
        
        // Exception Handling : Search Error
        guard docsRef.documents.count == 1 else {
            if docsRef.documents.count > 1 {
                throw StatErrorFS.MultipleStatFound
            } else {
                throw StatErrorFS.InternalError
            }
        }
        return docsRef.documents.first!
    }
}

//================================
// MARK: - Exception
//================================
enum StatErrorFS: LocalizedError {
    case UnexpectedConvertError
    case StatRetrievalByIdentifierFailed
    case MultipleStatFound
    case InternalError
    
    var errorDescription: String? {
        switch self {
        case .UnexpectedConvertError:
            return "Firestore: There was an unexpected error while Convert 'Statistics' details"
        case .StatRetrievalByIdentifierFailed:
            return "Firestore: Unable to retrieve 'Statistics' data using the provided identifier."
        case .MultipleStatFound:
            return "Firestore: Multiple 'Statistics' found. Expected only one."
        case .InternalError:
            return "Firestore: Internal Error Occurred while process 'Statistics' details"
        }
    }
}
