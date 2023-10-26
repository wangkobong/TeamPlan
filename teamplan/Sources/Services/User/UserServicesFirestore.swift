//
//  UserServicesFirestore.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/08/24.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation
import FirebaseFirestore

final class UserServicesFirestore{

    // Firestore setting
    let fs = Firestore.firestore()
    
    //================================
    // MARK: - Set User: SignUp
    //================================
    func setUser(reqUser: UserObject,
                          result: @escaping(Result<String, Error>) -> Void) {
        // Target Table
        let collectionRef = fs.collection("User")
        
        // Add User
        var docsRef: DocumentReference? = nil
        docsRef = collectionRef.addDocument(data: reqUser.toDictionary()){ error in
            
            // Exception Handling: Firestore
            if let error = error {
                result(.failure(error))
                
            // Return Firestore DocumnetID
            } else {
                result(.success(docsRef!.documentID))
            }
        }
    }
    
    //================================
    // MARK: - Get User
    //================================
    func getUser(identifier: String,
                 result: @escaping(Result<UserObject, Error>) -> Void) {
        
        // Target Table
        let collectionRef = fs.collection("User")
        
        
        // Search User
        collectionRef.whereField("user_id", isEqualTo: identifier).getDocuments() { (snapShot, error) in
            
            // Exception Handling: Internal Error (FirestoreServer)
            if let error = error {
                return result(.failure(error))
            }
            
            // Exception Handling: Identifier
            guard let response = snapShot else {
                return result(.failure(UserFSError.UserRetrievalByIdentifierFailed))
            }
            
            switch response.documents.count {
                
            case 1:
                let docs = response.documents.first!
                guard let user = UserObject(userData: docs.data(), docsId: docs.documentID) else {
                    
                    // Exception Handling: Converting Error
                    return result(.failure(UserFSError.UnexpectedConvertError))
                }
                return result(.success(user))
                
            // Exception Handling: Multiple User Found
            case let count where count > 1:
                return result(.failure(UserFSError.MultipleUserFound))
               
            // Exception Handling: Internal Error (FirestoreClient)
            default:
                return result(.failure(UserFSError.InternalError))
            }
        }
    }
}

//================================
// MARK: - Exception
//================================
enum UserFSError: LocalizedError {
    case UnexpectedSetError
    case UnexpectedGetError
    case UnexpectedConvertError
    case UserRetrievalByIdentifierFailed
    case MultipleUserFound
    case InternalError
    
    var errorDescription: String?{
        switch self {
        case .UnexpectedSetError:
            return "Firestore: There was an unexpected error while Set 'User' details"
        case .UnexpectedGetError:
            return "Firestore: There was an unexpected error while Get 'User' details"
        case .UnexpectedConvertError:
            return "Firestore: There was an unexpected error while Convert 'User' details"
        case .UserRetrievalByIdentifierFailed:
            return "Firestore: Unable to retrieve 'User' data using the provided identifier."
        case .MultipleUserFound:
            return "Firestore: Multiple 'User' found. Expected only one."
        case .InternalError:
            return "Firestore: Internal Error Occurred while process 'User' details"
        }
    }
}
