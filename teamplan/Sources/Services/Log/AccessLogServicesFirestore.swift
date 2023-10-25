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
    func setAccessLogFS(reqLog: AccessLog,
                       result: @escaping(Result<String, Error>) -> Void) {
        
        // Target Table
        let collectionRef = fs.collection("AccessLog")
        
        // Add AccessLog
        collectionRef.addDocument(data: reqLog.toDictionary()){ error in
            
            // Exception Handling: Internal Error (Firestore)
            if let error = error {
                result(.failure(error))
                
            } else {
                result(.success("Successfully set AccessLog at Firestore"))
            }
        }
    }
    
    //================================
    // MARK: - Get AccessLog
    //================================
    func getAccessLog(identifier: String,
                      result: @escaping(Result<AccessLog, Error>) -> Void) {
        
        // Target Table
        let collectionRef = fs.collection("AccessLog")
        
        // Search AccessLog
        collectionRef.whereField("log_user_id", isEqualTo: identifier).getDocuments() { (snapShot, error) in
            
            // Exception Handling : Internal Error (FirestoreServer)
            if let error = error {
                return result(.failure(error))
            }
            
            // Exception Handling : Docs Search Falied by Input Identifier
            guard let response = snapShot else {
                return result(.failure(StatFSError.StatRetrievalByIdentifierFailed))
            }
            
            switch response.documents.count {
            
            // Successfully Get AccessLog from Firestore
            case 1:
                let docs = response.documents.first!
                if let log = AccessLog(acclogData: docs.data()){
                    return result(.success(log))
                    
                // Exception Handling : Failed to fetch AccessLog from Docs
                } else {
                    return result(.failure(AcclogFSError.UnexpectedFetchError))
                }
                
            // Exception Handling : Multiple AccessLog Found
            case let count where count > 1:
                return result(.failure(AcclogFSError.MultipleAcclogFound))
                
            // Exception Handling : Internal Error (FetchDocument)
            default:
                return result(.failure(FirestoreErrorCode.internal as! Error))
            }
        }
    }
    
    //================================
    // MARK: - Update AccessLog
    //================================
    func updateAccessLog(identifier: String, updateAcclog: AccessLog,
                         result: @escaping(Result<String, Error>) -> Void) {
        
        let updatedData: [String : Any] = [
            "log_user_id" : updateAcclog.log_user_id,
            "log_access" : updateAcclog.log_access
        ]
        
        // Target Table
        let collectionRef = fs.collection("AccessLog")
        
        // Search AccessLog
        collectionRef.whereField("log_user_id", isEqualTo: identifier).getDocuments() { (snapShot, error) in
            
            // Exception Handling : Internal Error (FirestoreServer)
            if let error = error {
                return result(.failure(error))
            }
            
            // Exception Handling : Docs Search Falied by Input Identifier
            guard let response = snapShot else {
                return result(.failure(StatFSError.StatRetrievalByIdentifierFailed))
            }
            
            switch response.documents.count {
            
            // Successfully Get AccessLog from Firestore
            case 1:
                let docs = response.documents.first!
                
                // Update LogData
                docs.reference.setData(updatedData) { error in
                    if let error = error {
                        return result(.failure(error))
                    } else {
                        return result(.success("Successfully Set AccessLog"))
                    }
                }
                
            // Exception Handling : Multiple AccessLog Found
            case let count where count > 1:
                return result(.failure(AcclogFSError.MultipleAcclogFound))
                
            // Exception Handling : Internal Error (FetchDocument)
            default:
                return result(.failure(AcclogFSError.InternalError))
            }
        }
    }
}

//================================
// MARK: - Exception
//================================
enum AcclogFSError: LocalizedError {
    case StatRetrievalByIdentifierFailed
    case UnexpectedFetchError
    case MultipleAcclogFound
    case InternalError
    
    var errorDescription: String? {
        switch self {
        case .StatRetrievalByIdentifierFailed:
            return "Firestore: Unable to retrieve 'AccessLog' data using the provided identifier."
        case .UnexpectedFetchError:
            return "Firestore: There was an unexpected error while fetching 'AccessLog' details"
        case .MultipleAcclogFound:
            return "Firestore: Multiple 'AccessLog' found. Expected only one."
        case .InternalError:
            return "Firestore: Internal Error Occurred"
        }
    }
}
