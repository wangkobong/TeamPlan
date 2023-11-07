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
    //##### Async/Await #####
    func setUser(reqUser : UserObject) async throws -> String {
        
        // Target Table
        let collectionRef = fs.collection("User")
        
        do {
            // Set User
            let docsRef = try await collectionRef.addDocument(data: reqUser.toDictionary())
            
            // Successfully add User and Return DocsID
            return docsRef.documentID
            
        } catch {
            // Exception Handling: Internal Error (Firestore)
            print("(Firestore) Error Set User : \(error)")
            throw UserFSError.UnexpectedSetError
        }
    }
    
    //##### Result #####
    func setUser(reqUser: UserObject,
                          result: @escaping(Result<String, Error>) -> Void) {
        // Target Table
        let collectionRef = fs.collection("User")
        
        // Set User
        var docsRef: DocumentReference? = nil
        docsRef = collectionRef.addDocument(data: reqUser.toDictionary()){ error in
            
            // Exception Handling: Firestore
            if let error = error {
                print("(Firestore) Error Set User : \(error)")
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
    //##### Result #####
    func getUser(identifier: String,
                 result: @escaping(Result<UserObject, Error>) -> Void) {
        
        // Target Table
        let collectionRef = fs.collection("User")
        
        
        // Search User
        collectionRef.whereField("user_id", isEqualTo: identifier).getDocuments() { (snapShot, error) in
            
            // Exception Handling: Internal Error (FirestoreServer)
            if let error = error {
                print(error)
                return result(.failure(error))
            }
            
            // Exception Handling: Identifier
            guard let response = snapShot else {
                return result(.failure(UserFSError.UserRetrievalByIdentifierFailed))
            }
            
            // Exception Handling: Search Error
            guard response.documents.count == 1 else {
                if response.documents.count > 1 {
                    return result(.failure(UserFSError.MultipleUserFound))
                } else {
                    return result(.failure(UserFSError.InternalError))
                }
            }
            
            // Convert DocsData to Object
            let docs = response.documents.first!
            guard let user = UserObject(userData: docs.data(), docsId: docs.documentID) else {
                
                // Exception Handling: Convert Error
                return result(.failure(UserFSError.UnexpectedConvertError))
            }
            return result(.success(user))
        }
    }
    
    //================================
    // MARK: - Update User
    //================================
    //##### Async/Await #####
    func updateUser(updatedUser: UserObject) async throws {
        
        // Target Table
        let collectionRef = fs.collection("User")
 
        do {
            // Search User
            let response = try await collectionRef.whereField("user_id", isEqualTo: updatedUser.user_id).getDocuments()
            
            // Exception Handling : Search Error
            guard response.documents.count == 1 else {
                if response.documents.count > 1 {
                    throw UserFSError.MultipleUserFound
                } else {
                    throw UserFSError.UserRetrievalByIdentifierFailed
                }
            }
            
            // Get Current User
            guard let docs = response.documents.first,
                  var userEntity = UserObject(userData: docs.data(), docsId: docs.documentID) else {
                // Exception Handling : Convert Error
                throw UserFSError.UnexpectedConvertError
            }
            
            // Updated field Check
            var isUpdated = false
            isUpdated = util.updateFieldIfNeeded(&userEntity.user_fb_id, newValue: updatedUser.user_fb_id) || isUpdated
            isUpdated = util.updateFieldIfNeeded(&userEntity.user_name, newValue: updatedUser.user_name) || isUpdated
            isUpdated = util.updateFieldIfNeeded(&userEntity.user_status, newValue: updatedUser.user_status) || isUpdated
            isUpdated = util.updateFieldIfNeeded(&userEntity.user_login_at, newValue: updatedUser.user_login_at) || isUpdated
            isUpdated = util.updateFieldIfNeeded(&userEntity.user_updated_at, newValue: updatedUser.user_updated_at) || isUpdated
            
            // Update User
            try await docs.reference.setData(userEntity.toDictionary())
            
        } catch {
            print("(Firestore) Error Update User : \(error)")
            throw UserFSError.UnexpectedUpdateError
        }
    }
    
    //================================
    // MARK: - Delete User
    //================================
    //##### Async/Await #####
    func deleteUser(identifier: String) async throws {
        
        // Target Table
        let collectionRef = fs.collection("User")
        
        do{
            // Search User
            let response = try await collectionRef.whereField("user_id", isEqualTo: identifier).getDocuments()
            
            // Exception Handling : Search Error
            guard response.documents.count == 1 else {
                if response.documents.count > 1 {
                    throw UserFSError.MultipleUserFound
                } else {
                    throw UserFSError.UserRetrievalByIdentifierFailed
                }
            }
            guard let docs = response.documents.first else {
                // Exception Handling: Fetch Error
                throw UserFSError.UnexpectedFetchError
            }
            // Delete User
            try await docs.reference.delete()
        } catch {
            print("(Firestore) Error Delete User : \(error)")
            throw UserFSError.UnexpectedDeleteError
        }
    }
}

//================================
// MARK: - Exception
//================================
enum UserFSError: LocalizedError {
    case UnexpectedSetError
    case UnexpectedGetError
    case UnexpectedUpdateError
    case UnexpectedDeleteError
    case UnexpectedFetchError
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
        case .UnexpectedUpdateError:
            return "Firestore: There was an unexpected error while Update 'User' details"
        case .UnexpectedDeleteError:
            return "Firestore: There was an unexpected error while Delete 'User' details"
        case .UnexpectedFetchError:
            return "Firestore: There was an unexpected error while Fetch 'User' details from DocumentReference"
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

