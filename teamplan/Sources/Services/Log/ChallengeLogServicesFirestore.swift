//
//  ChallengeLogServicesFirestore.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/10/20.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation
import FirebaseFirestore

final class ChallengeLogServicesFirestore{
    
    // Firestore setting
    let fs = Firestore.firestore()
    
    //================================
    // MARK: - Set ChallengeLog
    //================================
    //##### Async/Await #####
    func setChallengeLog(reqLog: ChallengeLog) async throws {
        
        // Target Table
        let collectionRef = fs.collection("ChallengeLog")
        
        do
        {
            // Set ChallengeLog
            try await collectionRef.addDocument(data: reqLog.toDictionary())
        } catch {
            print("(Firestore) Error Set ChallengeLog : \(error)")
            throw ChallengeLogErrorFS.UnexpectedSetError
        }
    }
    
    //##### Result #####
    func setChallengeLog(reqLog: ChallengeLog,
                           result: @escaping(Result<String, Error>) -> Void) {
        
        // Target Table
        let collectionRef = fs.collection("ChallengeLog")
        
        // Add ChallengeLog
        collectionRef.addDocument(data: reqLog.toDictionary()){ error in
            
            // Exception Handling: Firestore
            if let error = error {
                print("(Firestore) Error Set ChallengeLog : \(error)")
                result(.failure(ChallengeLogErrorFS.UnexpectedSetError))
            } else {
                result(.success("Successfully set ChallengeLog at Firestore"))
            }
        }
    }
    
    //================================
    // MARK: - Get ChallengeLog
    //================================
    //##### Result #####
    func getChallengeLog(identifier: String,
                         result: @escaping(Result<ChallengeLog, Error>) -> Void) {
        
        // Target Table
        let collectionRef = fs.collection("ChallengeLog")
        
        collectionRef.whereField("log_user_id", isEqualTo: identifier).getDocuments() { (snapShot, error) in
            
            // Exception Handling : Internal Error (FirestoreServer)
            if let error = error {
                print("(Firestore) Error Get ChallengeLog : \(error)")
                return result(.failure(ChallengeLogErrorFS.InternalError))
            }
            
            // Exception Handling : Identifier
            guard let response = snapShot else {
                return result(.failure(ChallengeLogErrorFS.ChallengeLogRetrievalByIdentifierFailed))
            }
            
            // Exception Handling : Search Error
            guard response.documents.count == 1 else {
                if response.documents.count > 1 {
                    return result(.failure(ChallengeLogErrorFS.MultipleChallengeLogFound))
                } else {
                    return result(.failure(ChallengeLogErrorFS.InternalError))
                }
            }
            
            // Convert DocsData to Object
            let docs = response.documents.first!
            guard let log = ChallengeLog(challengeData: docs.data()) else {
                // Exception Handling : Failed to fetch ChallengeLog from Docs
                return result(.failure(ChallengeLogErrorFS.UnexpectedConvertError))
            }
            return result(.success(log))
        }
    }
    
    //================================
    // MARK: - Update ChallengeLog
    //================================
    //##### Result #####
    func updateChallengeLog(identifier: String, updatedLog: ChallengeLog,
                            result: @escaping(Result<String, Error>) -> Void) {
        
        // Target Table
        let collectionRef = fs.collection("ChallengeLog")
        
        collectionRef.whereField("log_user_id", isEqualTo: identifier).getDocuments() { (snapShot, error) in
            
            // Exception Handling : Internal Error (FirestoreServer)
            if let error = error {
                print("(Firestore) Error Update ChallengeLog : \(error)")
                return result(.failure(ChallengeLogErrorFS.InternalError))
            }
            
            // Exception Handling : Identifier
            guard let response = snapShot else {
                return result(.failure(ChallengeLogErrorFS.ChallengeLogRetrievalByIdentifierFailed))
            }
            
            // Exception Handling : Search Error
            guard response.documents.count == 1 else {
                if response.documents.count > 1 {
                    return result(.failure(ChallengeLogErrorFS.MultipleChallengeLogFound))
                } else {
                    return result(.failure(ChallengeLogErrorFS.InternalError))
                }
            }
            
            let docs = response.documents.first!
            docs.reference.updateData(updatedLog.toDictionary()) { error in
                if let error = error {
                    print("(Firestore) Error Update ChallengeLog : \(error)")
                    return result(.failure(error))
                } else {
                    return result(.success("Successfully Update ChallengeLog"))
                }
            }
        }
    }
    
    //================================
    // MARK: - Delete ChallengeLog
    //================================
    //##### Async/Await #####
    func deleteChallengeLog(identifier: String) async throws {
        
        // Target Table
        let collectionRef = fs.collection("ChallengeLog")
        
        do {
            let response = try await collectionRef.whereField("log_user_id", isEqualTo: identifier).getDocuments()
            
            // Exception Handling : Search Error
            guard response.documents.count == 1 else {
                if response.documents.count > 1 {
                    throw ChallengeLogErrorFS.MultipleChallengeLogFound
                } else {
                    throw ChallengeLogErrorFS.InternalError
                }
            }
            
            // Fetch Document
            guard let docs = response.documents.first else {
                throw ChallengeLogErrorFS.UnexpectedFetchError
            }
            
            // Delete ChallengeLog
            try await docs.reference.delete()
            
        } catch {
            print("(Firestore) Error Delete ChallengeLog : \(error)")
            throw ChallengeLogErrorFS.UnexpectedDeleteError
        }
    }
}

//================================
// MARK: - Exception
//================================
enum ChallengeLogErrorFS: LocalizedError {
    case UnexpectedSetError
    case UnexpectedGetError
    case UnexpectedUpdateError
    case UnexpectedDeleteError
    case UnexpectedFetchError
    case UnexpectedConvertError
    case ChallengeLogRetrievalByIdentifierFailed
    case MultipleChallengeLogFound
    case InternalError
    
    var errorDescription: String?{
        switch self {
        case .UnexpectedSetError:
            return "Firestore: There was an unexpected error while Set 'ChallengeLog' details"
        case .UnexpectedGetError:
            return "Firestore: There was an unexpected error while Get 'ChallengeLog' details"
        case .UnexpectedUpdateError:
            return "Firestore: There was an unexpected error while Update 'ChallengeLog' details"
        case .UnexpectedDeleteError:
            return "Firestore: There was an unexpected error while Delete 'ChallengeLog' details"
        case .UnexpectedFetchError:
            return "Firestore: There was an unexpected error while Fetch 'ChallengeLog' details from DocumentReference"
        case .UnexpectedConvertError:
            return "Firestore: There was an unexpected error while Convert 'ChallengeLog' details"
        case .ChallengeLogRetrievalByIdentifierFailed:
            return "Firestore: Unable to retrieve 'ChallengeLog' data using the provided identifier."
        case .MultipleChallengeLogFound:
            return "Firestore: Multiple 'ChallengeLog' found. Expected only one."
        case .InternalError:
            return "Firestore: Internal Error Occurred while process 'ChallengeLog' details"
        }
    }
}
