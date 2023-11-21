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
    func setStatistics(reqStat : StatisticsObject) async throws {
        
        // Search & Set Data
        let collectionRef = fs.collection("Stat")
        let docsRef = try await collectionRef.addDocument(data: reqStat.toDictionary())
    }
    
    //================================
    // MARK: - Get Statistics
    //================================
    func getStatistics(from userId: String) async throws -> StatisticsObject {
        
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
        
        // Convert to Object & Get
        let docs = docsRef.documents.first!
        guard let reqStat = StatisticsObject(statData: docs.data()) else {
            throw StatErrorFS.UnexpectedConvertError
        }
        return reqStat
    }

    //================================
    // MARK: - Update Statistics
    //================================
    func updateStatistics(to updatedData: StatisticsObject) async throws {
        
        // Search Data
        let collectionRef = fs.collection("Stat")
        let docsRef = try await collectionRef.whereField("stat_user_id", isEqualTo: updatedData.stat_user_id).getDocuments()
        
        // Exception Handling : Search Error
        guard docsRef.documents.count == 1 else {
            if docsRef.documents.count > 1 {
                throw StatErrorFS.MultipleStatFound
            } else {
                throw StatErrorFS.InternalError
            }
        }
        
        // Update Documents
        let docs = docsRef.documents.first!
        try await docs.reference.updateData(updatedData.toDictionary())
    }
    
    //================================
    // MARK: - Delete Statistics
    //================================
    func deleteStatistics(to userId: String) async throws {
        
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
        // Delete Documents
        let docs = docsRef.documents.first!
        try await docs.reference.delete()
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

//================================
// MARK: - Legacy
//================================
extension StatisticsServicesFirestore{
    
    // Set Stat
    func setStatistics(reqStat: StatisticsObject,
                         result: @escaping(Result<String, Error>) -> Void) {
        let collectionRef = fs.collection("Stat")
        collectionRef.addDocument(data: reqStat.toDictionary()){ error in
            if let error = error {
                print("(Firestore) Error Set Statistics : \(error)")
                result(.failure(error))
            } else {
                result(.success("Successfully set Statistics at Firestore"))
            }
        }
    }
    
    // Get Stat
    func getStatistics(identifier: String,
                       result: @escaping(Result<StatisticsObject, Error>) -> Void) {
        let collectionRef = fs.collection("Stat")
        collectionRef.whereField("stat_user_id", isEqualTo: identifier).getDocuments() { (snapShot, error) in
            if let error = error {
                print("(Firestore) Error Get Statistics : \(error)")
                return result(.failure(error))
            }
            guard let response = snapShot else {
                return result(.failure(StatErrorFS.StatRetrievalByIdentifierFailed))
            }
            guard response.documents.count == 1 else {
                if response.documents.count > 1 {
                    return result(.failure(StatErrorFS.MultipleStatFound))
                } else {
                    return result(.failure(StatErrorFS.InternalError))
                }
            }
            let docs = response.documents.first!
            guard let stat = StatisticsObject(statData: docs.data()) else {
                return result(.failure(StatErrorFS.UnexpectedConvertError))
            }
            return result(.success(stat))
        }
    }
    
    // Update Stat
    func updateStatistics(identifier: String, updatedStat: StatisticsDTO,
                          result: @escaping(Result<String, Error>) -> Void) {
        let collectionRef = fs.collection("Stat")
        collectionRef.whereField("stat_user_id", isEqualTo: identifier).getDocuments() { (snapShot, error) in
            if let error = error {
                print("(Firestore) Error Update Statistics : \(error)")
                return result(.failure(error))
            }
            guard let response = snapShot else {
                return result(.failure(StatErrorFS.StatRetrievalByIdentifierFailed))
            }
            guard response.documents.count == 1 else {
                if response.documents.count > 1 {
                    return result(.failure(StatErrorFS.MultipleStatFound))
                } else {
                    return result(.failure(StatErrorFS.InternalError))
                }
            }
            guard let docs = response.documents.first,
                  var statEntity = StatisticsObject(statData: docs.data()) else {
                return result(.failure(StatErrorFS.UnexpectedConvertError))
            }
            docs.reference.updateData(statEntity.toDictionary()) { error in
                if let error = error {
                    print("(Firestore) Error Update Statistics : \(error)")
                    return result(.failure(error))
                } else {
                    return result(.success("Successfully Update Statistics"))
                }
            }
        }
    }
}
