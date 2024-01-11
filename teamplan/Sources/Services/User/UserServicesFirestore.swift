//
//  UserServicesFirestore.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/08/24.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

//================================
// MARK: - Main Function
//================================
final class UserServicesFirestore{

    //--------------------
    // Parameter
    //--------------------
    let util = Utilities()
    let fs = Firestore.firestore()
    
    //--------------------
    // Set
    //--------------------
    func setUser(with user: UserObject) async throws {
        // Search & Set Data
        let collection = fetchCollection()
        try await collection.addDocument(data: user.toDictionary())
    }
    
    //--------------------
    // Get
    //--------------------
    func getUser(from userId: String) async throws -> UserObject {
        // Fetch Document
        let docs = try await fetchDocument(with: userId)
        // Convert & Return
        return try convertToUser(with: docs.data())
    }
    
    //--------------------
    // Update
    //--------------------
    func updateUser(with updatedUser: UserObject) async throws {
        // Fetch Document
        let docs = try await fetchDocument(with: updatedUser.user_id)
        // Update Document
        try await docs.reference.updateData(updatedUser.toDictionary())
    }
    
    //--------------------
    // Delete
    //--------------------
    func deleteUser(with userId: String) async throws {
        // Fetch Document
        let docs = try await fetchDocument(with: userId)
        // Delete Document
        try await docs.reference.delete()
    }
}

//================================
// MARK: - Support Function
//================================
extension UserServicesFirestore{
    
    // Fetch: Collection
    private func fetchCollection() -> CollectionReference {
        return fs.collection("User")
    }
    
    // Fetch: Document
    private func fetchDocument(with userId: String) async throws -> QueryDocumentSnapshot {
        // fetch reference
        let docsRef = try await fetchCollection()
            .whereField("user_id", isEqualTo: userId)
            .getDocuments()
        
        // convert & return
        guard let docs = docsRef.documents.first else {
            throw UserErrorFS.UnexpectedConvertDocsError
        }
        return docs
    }
    
    // Convert: to Object
    private func convertToUser(with data: [String:Any]) throws -> UserObject {
        guard let user = UserObject(userData: data) else {
            throw UserErrorFS.UnexpectedConvertObjectError
        }
        return user
    }
}

//================================
// MARK: - Exception
//================================
enum UserErrorFS: LocalizedError {
    case UnexpectedConvertDocsError
    case UnexpectedConvertObjectError
    
    var errorDescription: String?{
        switch self {
        case .UnexpectedConvertDocsError:
            return "Firestore: There was an unexpected error while Convert Reference to  'User' Document"
        case .UnexpectedConvertObjectError:
            return "Firestore: There was an unexpected error while Convert Document to  'User' Object"
        }
    }
}
