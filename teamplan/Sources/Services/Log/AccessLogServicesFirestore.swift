//
//  AccessLogServicesFirestore.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/10/20.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

final class AccessLogServicesFirestore{

    //================================
    // MARK: - Parameter Setting
    //================================
    let fs = Firestore.firestore()
    
    //================================
    // MARK: - Set AccessLog
    //================================
    func setLog(reqLog: AccessLog) async throws {
        
        // Search & Set Data
        let collectionRef = fs.collection("AccessLog")
        try await collectionRef.addDocument(data: reqLog.toDictionary())
    }
    
    //================================
    // MARK: - Get AccessLog
    //================================
    func getLog(from userId: String) async throws -> AccessLog {
        
        // Search Data
        let collectionRef = fs.collection("AccessLog")
        let docsRef = try await collectionRef.whereField("log_user_id", isEqualTo: userId).getDocuments()
        
        // Exception Handling : Search Error
        guard docsRef.documents.count == 1 else {
            if docsRef.documents.count > 1 {
                throw AccessLogErrorFS.MultipleAcclogFound
            } else {
                throw AccessLogErrorFS.InternalError
            }
        }
        
        // Convert to Log & Get
        let docs = docsRef.documents.first!
        guard let log = AccessLog(logData: docs.data()) else {
            throw AccessLogErrorFS.UnexpectedConvertError
        }
        return log
    }
    
    //================================
    // MARK: - Update AccessLog
    //================================
    func updateLog(to updatedData: AccessLog) async throws {
        
        // Search Data
        let collectionRef = fs.collection("AccessLog")
        let docsRef = try await collectionRef.whereField("log_user_id", isEqualTo: updatedData.log_user_id).getDocuments()
        
        // Exception Handling : Search Error
        guard docsRef.documents.count == 1 else {
            if docsRef.documents.count > 1 {
                throw AccessLogErrorFS.MultipleAcclogFound
            } else {
                throw AccessLogErrorFS.InternalError
            }
        }
        // Update Log
        let docs = docsRef.documents.first!
        try await docs.reference.updateData(updatedData.toDictionary())
    }
    
    
    //================================
    // MARK: - Delete AccessLog
    //================================
    func deleteLog(to userId: String) async throws {
        
        // Search Data
        let collectionRef = fs.collection("AccessLog")
        let docsRef = try await collectionRef.whereField("log_user_id", isEqualTo: userId).getDocuments()
        
        // Exception Handling : Search Error
        guard docsRef.documents.count == 1 else {
            if docsRef.documents.count > 1 {
                throw AccessLogErrorFS.MultipleAcclogFound
            } else {
                throw AccessLogErrorFS.InternalError
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
enum AccessLogErrorFS: LocalizedError {
    case UnexpectedConvertError
    case AcclogRetrievalByIdentifierFailed
    case MultipleAcclogFound
    case InternalError
    
    var errorDescription: String? {
        switch self {
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

//================================
// MARK: - Legacy
//================================
extension AccessLogServicesFirestore{
    // Set Log
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
    
    // Get Log
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
    
    // Update Log
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
}

