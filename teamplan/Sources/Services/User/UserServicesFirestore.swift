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

final class UserServicesFirestore{

    //================================
    // MARK: - Parameter Setting
    //================================
    let util = Utilities()
    let fs = Firestore.firestore()
    
    //================================
    // MARK: - Set User
    //================================
    func setUser(reqUser : UserObject) async throws -> String {
        
        // Search & Set Data
        let collectionRef = fs.collection("User")
        let docsRef = try await collectionRef.addDocument(data: reqUser.toDictionary())
        return docsRef.documentID
    }
    
    //================================
    // MARK: - Get User
    //================================
    func getUser(from userId: String) async throws -> UserObject {
        
        // Search Data
        let collectionRef = fs.collection("User")
        let docsRef = try await collectionRef.whereField("user_id", isEqualTo: userId).getDocuments()
        
        // Exception Handling : Search Error
        guard docsRef.documents.count == 1 else {
            if docsRef.documents.count > 1 {
                throw UserErrorFS.MultipleUserFound
            } else {
                throw UserErrorFS.InternalError
            }
        }
        // Convert to Object & Get
        let docs = docsRef.documents.first!
        guard let reqUser = UserObject(userData: docs.data(), docsId: docs.documentID) else {
            throw UserErrorFS.UnexpectedConvertError
        }
        return reqUser
    }
    
    //================================
    // MARK: - Update User
    //================================
    func updateUser(to updatedData: UserObject) async throws {
        
        // Search Data
        let collectionRef = fs.collection("User")
        let docsRef = try await collectionRef.whereField("user_id", isEqualTo: updatedData.user_id).getDocuments()
        
        // Exception Handling : Search Error
        guard docsRef.documents.count == 1 else {
            if docsRef.documents.count > 1 {
                throw UserErrorFS.MultipleUserFound
            } else {
                throw UserErrorFS.InternalError
            }
        }
        // Update Documents
        let docs = docsRef.documents.first!
        try await docs.reference.updateData(updatedData.toDictionary())
    }
    
    //================================
    // MARK: - Delete User
    //================================
    func deleteUser(to userId: String) async throws {
        
        // Search Data
        let collectionRef = fs.collection("User")
        let docsRef = try await collectionRef.whereField("user_id", isEqualTo: userId).getDocuments()
        
        // Exception Handling : Search Error
        guard docsRef.documents.count == 1 else {
            if docsRef.documents.count > 1 {
                throw UserErrorFS.MultipleUserFound
            } else {
                throw UserErrorFS.InternalError
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
enum UserErrorFS: LocalizedError {
    case UserRetrievalByIdentifierFailed
    case UnexpectedConvertError
    case MultipleUserFound
    case InternalError
    
    var errorDescription: String?{
        switch self {
        case .UserRetrievalByIdentifierFailed:
            return "Firestore: Unable to retrieve 'User' data using the provided identifier."
        case .UnexpectedConvertError:
            return "Firestore: There was an unexpected error while Convert 'User' details"
        case .MultipleUserFound:
            return "Firestore: Multiple 'User' found. Expected only one."
        case .InternalError:
            return "Firestore: Internal Error Occurred while process 'User' details"
        }
    }
}
