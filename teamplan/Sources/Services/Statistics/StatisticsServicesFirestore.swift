//
//  StatisticsServicesFirestore.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/10/20.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation
import FirebaseFirestore

final class StatisticsServicesFirestore{
    
    // Firestore setting
    let fs = Firestore.firestore()
    
    //================================
    // MARK: - Set Statistics
    //================================
    func setStatistics(reqStat: StatisticsObject,
                         result: @escaping(Result<String, Error>) -> Void) {
        
        // Target Table
        let collectionRef = fs.collection("Stat")
        
        // Add Statistics
        collectionRef.addDocument(data: reqStat.toDictionary()){ error in
            
            // Exception Handling: Internal Error (FirestoreServer)
            if let error = error {
                result(.failure(error))
            } else {
                result(.success("Successfully set Statistics at Firestore"))
            }
        }
    }
    
    //================================
    // MARK: - Get Statistics
    //================================
    func getStatistics(identifier: String,
                       result: @escaping(Result<StatisticsObject, Error>) -> Void) {
        
        // Target Table
        let collectionRef = fs.collection("Stat")
        
        // Search Statistics
        collectionRef.whereField("stat_user_id", isEqualTo: identifier).getDocuments() { (snapShot, error) in
            
            // Exception Handling : Internal Error (FirestoreServer)
            if let error = error {
                return result(.failure(error))
            }
            
            // Exception Handling : Docs Search Falied by Input Identifier
            guard let response = snapShot else {
                return result(.failure(StatFSError.StatRetrievalByIdentifierFailed))
            }
            
            switch response.documents.count {
                
            // Successfully Get Statistics from Firestore
            case 1:
                let docs = response.documents.first!
                if let stat = StatisticsObject(statData: docs.data()) {
                    return result(.success(stat))
                    
                // Exception Handling : Failed to fetch Statistics from Docs
                } else {
                    return result(.failure(StatFSError.UnexpectedGetError))
                }
                
            // Exception Handling : Multiple User Found
            case let count where count > 1:
                return result(.failure(StatFSError.MultipleStatFound))
                
            // Exception Handling : Internal Error (FetchDocument)
            default:
                return result(.failure(FirestoreErrorCode.internal as! Error))
            }
        }
    }
    
    //================================
    // MARK: - Update Statistics
    //================================
    func updateStatistics(identifier: String, updatedStatInfo: StatisticsDTO,
                          result: @escaping(Result<String, Error>) -> Void) {
        
        let updatedData = StatisticsObject(updatedStat: updatedStatInfo)
        
        // Target Table
        let collectionRef = fs.collection("Stat")
        
        // Search Statistics
        collectionRef.whereField("stat_user_id", isEqualTo: identifier).getDocuments() { (snapShot, error) in
            
            // Exception Handling : Internal Error (FirestoreServer)
            if let error = error {
                return result(.failure(error))
            }
            
            // Exception Handling : Docs Search Falied by Input Identifier
            guard let response = snapShot else {
                return result(.failure(StatFSError.StatRetrievalByIdentifierFailed))
            }
            
            switch response.documents.count {
                
            // Successfully Get Statistics from Firestore
            case 1:
                let docs = response.documents.first!
                
                // Update Statistics
                docs.reference.setData(updatedData.toDictionary()) { error in
                    if let error = error {
                        return result(.failure(error))
                    } else {
                        return result(.success("Successfully Update Statistics"))
                    }
                }
                
            // Exception Handling : Multiple User Found
            case let count where count > 1:
                return result(.failure(StatFSError.MultipleStatFound))
                
            // Exception Handling : Internal Error (FetchDocument)
            default:
                return result(.failure(FirestoreErrorCode.internal as! Error))
            }
        }
    }
}

//================================
// MARK: - Exception
//================================
enum StatFSError: LocalizedError {
    case UnexpectedGetError
    case StatRetrievalByIdentifierFailed
    case MultipleStatFound
    
    var errorDescription: String? {
        switch self {
        case .UnexpectedGetError:
            return "Firestore: There was an unexpected error while Get 'Statistics' details"
        case .StatRetrievalByIdentifierFailed:
            return "Firestore: Unable to retrieve 'Statistics' data using the provided identifier."
        case .MultipleStatFound:
            return "Firestore: Multiple 'Statistics' found. Expected only one."
        }
    }
}
