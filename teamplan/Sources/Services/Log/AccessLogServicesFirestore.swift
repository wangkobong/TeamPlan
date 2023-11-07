//
//  AccessLogServicesFirestore.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/10/20.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation
import FirebaseFirestore

final class AccessLogServicesFirestore{
    
    // Firestore setting
    let fs = Firestore.firestore()
    
    //================================
    // MARK: - Set AccessLog
    //================================
    //##### Async/Await #####
    func setAccessLog(reqLog: AccessLog) async throws {
        
        // Target Table
        let collectionRef = fs.collection("AccessLog")
        
        do {
            // Set AccessLog
            try await collectionRef.addDocument(data: reqLog.toDictionary())
            
        } catch {
            print("(Firestore) Error Set AccessLog : \(error)")
            throw AccessLogErrorFS.UnexpectedSetError
        }
    }
    
    //##### Result #####
    func setAccessLog(reqLog: AccessLog,
                       result: @escaping(Result<String, Error>) -> Void) {
        
        // Target Table
        let collectionRef = fs.collection("AccessLog")
        
        // Add AccessLog
        collectionRef.addDocument(data: reqLog.toDictionary()){ error in
            
            // Exception Handling: Internal Error (Firestore)
            if let error = error {
                print("(Firestore) Error Set AccessLog : \(error)")
                result(.failure(error))
                
            } else {
                result(.success("Successfully set AccessLog at Firestore"))
            }
        }
    }
    
    //================================
    // MARK: - Get AccessLog
    //================================
    //##### Result #####
    func getAccessLog(identifier: String,
                      result: @escaping(Result<AccessLog, Error>) -> Void) {
        
        // Target Table
        let collectionRef = fs.collection("AccessLog")
        
        // Search AccessLog
        collectionRef.whereField("log_user_id", isEqualTo: identifier).getDocuments() { (snapShot, error) in
            
            // Exception Handling : Internal Error (FirestoreServer)
            if let error = error {
                print("(Firestore) Error Get AccessLog : \(error)")
                return result(.failure(AccessLogErrorFS.InternalError))
            }
            
            // Exception Handling : Identifier
            guard let response = snapShot else {
                return result(.failure(AccessLogErrorFS.AcclogRetrievalByIdentifierFailed))
            }
            
            // Exception Handling : Search Error
            guard response.documents.count == 1 else {
                if response.documents.count > 1 {
                    return result(.failure(AccessLogErrorFS.MultipleAcclogFound))
                } else {
                    return result(.failure(AccessLogErrorFS.InternalError))
                }
            }
            
            // Convert DocsData to Object
            let docs = response.documents.first!
            guard let log = AccessLog(logData: docs.data()) else {
                
                // Exception Handling : Failed to fetch AccessLog from Docs
                return result(.failure(AccessLogErrorFS.UnexpectedConvertError))
            }
            return result(.success(log))
        }
    }
    
    //================================
    // MARK: - Update AccessLog
    //================================
    //##### Result #####
    func updateAccessLog(identifier: String, updatedLog: AccessLog,
                         result: @escaping(Result<String, Error>) -> Void) {
        // Target Table
        let collectionRef = fs.collection("AccessLog")
        
        // Search AccessLog
        collectionRef.whereField("log_user_id", isEqualTo: identifier).getDocuments() { (snapShot, error) in
            
            // Exception Handling : Internal Error (FirestoreServer)
            if let error = error {
                print("(Firestore) Error Update AccessLog : \(error)")
                return result(.failure(error))
            }
            
            // Exception Handling : Docs Search Falied by Input Identifier
            guard let response = snapShot else {
                return result(.failure(AccessLogErrorFS.AcclogRetrievalByIdentifierFailed))
            }
            
            // Exception Handling : Search Error
            guard response.documents.count == 1 else {
                if response.documents.count > 1 {
                    return result(.failure(AccessLogErrorFS.MultipleAcclogFound))
                } else {
                    return result(.failure(AccessLogErrorFS.InternalError))
                }
            }
            
            let docs = response.documents.first!
            
            // Update LogData
            let updatedData: [String : Any] = [
                "log_access" : updatedLog.log_access
            ]
            
            docs.reference.updateData(updatedData) { error in
                if let error = error {
                    print("(Firestore) Error Update AccessLog : \(error)")
                    return result(.failure(error))
                } else {
                    return result(.success("Successfully Update AccessLog"))
                }
            }
        }
    }
    
    //================================
    // MARK: - Delete AccessLog
    //================================
    //##### Async/Await #####
    func deleteAccessLog(identifier: String) async throws {
        
        // Target Table
        let collectionRef = fs.collection("AccessLog")
        
        do{
            let response = try await collectionRef.whereField("log_user_id", isEqualTo: identifier).getDocuments()
            
            // Exception Handling : Search Error
            guard response.documents.count == 1 else {
                if response.documents.count > 1 {
                    throw AccessLogErrorFS.MultipleAcclogFound
                } else {
                    throw AccessLogErrorFS.AcclogRetrievalByIdentifierFailed
                }
            }
            
            // Fetch Document
            guard let docs = response.documents.first else {
                throw AccessLogErrorFS.UnexpectedFetchError
            }
            
            // Delete AccessLog
            try await docs.reference.delete()
            
        } catch {
            // Exception Handling : Internal Error (FirestoreServer)
            print("(Firestore) Error Delete AccessLog : \(error)")
            throw AccessLogErrorFS.InternalError
        }
    }
}

//================================
// MARK: - Exception
//================================
enum AccessLogErrorFS: LocalizedError {
    case UnexpectedSetError
    case UnexpectedGetError
    case UnexpectedUpdateError
    case UnexpectedDeleteError
    case UnexpectedFetchError
    case UnexpectedConvertError
    case AcclogRetrievalByIdentifierFailed
    case MultipleAcclogFound
    case InternalError
    
    var errorDescription: String? {
        switch self {
        case .UnexpectedSetError:
            return "Firestore: There was an unexpected error while Set 'Accesslog' details"
        case .UnexpectedGetError:
            return "Firestore: There was an unexpected error while Get 'Accesslog' details"
        case .UnexpectedUpdateError:
            return "Firestore: There was an unexpected error while Update 'Accesslog' details"
        case .UnexpectedDeleteError:
            return "Firestore: There was an unexpected error while Delete 'Accesslog' details"
        case .UnexpectedFetchError:
            return "Firestore: There was an unexpected error while Fetch 'Accesslog' details from DocumentReference"
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
