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
    //##### Async/Await #####
    func setStatistics(reqStat : StatisticsObject) async throws {
        
        // Target Table
        let collectionRef = fs.collection("Stat")

        do {
            // Set User
            try await collectionRef.addDocument(data: reqStat.toDictionary())
            
        } catch {
            print("(Firestore) Error Set Statistics : \(error)")
            throw StaticErrorFS.UnexpectedSetError
        }
    }
    
    //##### Result #####
    func setStatistics(reqStat: StatisticsObject,
                         result: @escaping(Result<String, Error>) -> Void) {
        
        // Target Table
        let collectionRef = fs.collection("Stat")
        
        // Set Statistics
        collectionRef.addDocument(data: reqStat.toDictionary()){ error in
            
            // Exception Handling: Internal Error (FirestoreServer)
            if let error = error {
                print("(Firestore) Error Set Statistics : \(error)")
                result(.failure(error))
            } else {
                result(.success("Successfully set Statistics at Firestore"))
            }
        }
    }
    
    //================================
    // MARK: - Get Statistics
    //================================
    //##### Result #####
    func getStatistics(identifier: String,
                       result: @escaping(Result<StatisticsObject, Error>) -> Void) {
        
        // Target Table
        let collectionRef = fs.collection("Stat")
        
        // Search Statistics
        collectionRef.whereField("stat_user_id", isEqualTo: identifier).getDocuments() { (snapShot, error) in
            
            // Exception Handling : Internal Error (FirestoreServer)
            if let error = error {
                print("(Firestore) Error Get Statistics : \(error)")
                return result(.failure(error))
            }
            
            // Exception Handling : Identifier
            guard let response = snapShot else {
                return result(.failure(StaticErrorFS.StatRetrievalByIdentifierFailed))
            }
            
            // Exception Handling : Search Error
            guard response.documents.count == 1 else {
                if response.documents.count > 1 {
                    return result(.failure(StaticErrorFS.MultipleStatFound))
                } else {
                    return result(.failure(StaticErrorFS.InternalError))
                }
            }
            
            // Convert DocsData to Object
            let docs = response.documents.first!
            guard let stat = StatisticsObject(statData: docs.data()) else {
                
                // Exception Handling : Convert Error
                return result(.failure(StaticErrorFS.UnexpectedConvertError))
            }
            return result(.success(stat))
        }
    }
    
    //================================
    // MARK: - Update Statistics
    //================================
    //##### Result #####
    func updateStatistics(identifier: String, updatedStat: StatisticsDTO,
                          result: @escaping(Result<String, Error>) -> Void) {
        
        // Target Table
        let collectionRef = fs.collection("Stat")
        
        // Search Statistics
        collectionRef.whereField("stat_user_id", isEqualTo: identifier).getDocuments() { (snapShot, error) in
            
            // Exception Handling : Internal Error (FirestoreServer)
            if let error = error {
                print("(Firestore) Error Update Statistics : \(error)")
                return result(.failure(error))
            }
            
            // Exception Handling : Docs Search Falied by Input Identifier
            guard let response = snapShot else {
                return result(.failure(StaticErrorFS.StatRetrievalByIdentifierFailed))
            }
            
            // Exception Handling: Search Error
            guard response.documents.count == 1 else {
                if response.documents.count > 1 {
                    return result(.failure(StaticErrorFS.MultipleStatFound))
                } else {
                    return result(.failure(StaticErrorFS.InternalError))
                }
            }
            
            // Get Entity
            guard let docs = response.documents.first,
                  var statEntity = StatisticsObject(statData: docs.data()) else {
                return result(.failure(StaticErrorFS.UnexpectedConvertError))
            }
            
            // Updated field Check
            var isUpdated = false
            isUpdated = self.util.updateFieldIfNeeded(&statEntity.stat_term, newValue: updatedStat.stat_term) || isUpdated
            isUpdated = self.util.updateFieldIfNeeded(&statEntity.stat_drop, newValue: updatedStat.stat_drop) || isUpdated
            isUpdated = self.util.updateFieldIfNeeded(&statEntity.stat_proj_reg, newValue: updatedStat.stat_proj_reg) || isUpdated
            isUpdated = self.util.updateFieldIfNeeded(&statEntity.stat_proj_fin, newValue: updatedStat.stat_proj_fin) || isUpdated
            isUpdated = self.util.updateFieldIfNeeded(&statEntity.stat_proj_alert, newValue: updatedStat.stat_proj_alert) || isUpdated
            isUpdated = self.util.updateFieldIfNeeded(&statEntity.stat_proj_ext, newValue: updatedStat.stat_proj_ext) || isUpdated
            isUpdated = self.util.updateFieldIfNeeded(&statEntity.stat_todo_reg, newValue: updatedStat.stat_todo_reg) || isUpdated
            isUpdated = self.util.updateFieldIfNeeded(&statEntity.stat_chlg_step, newValue: updatedStat.stat_chlg_step) || isUpdated
            isUpdated = self.util.updateFieldIfNeeded(&statEntity.stat_mychlg, newValue: updatedStat.stat_mychlg) || isUpdated
            isUpdated = self.util.updateFieldIfNeeded(&statEntity.stat_upload_at, newValue: updatedStat.stat_upload_at) || isUpdated
            
            // Update Statistics
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
    
    //================================
    // MARK: - Delete Statistics
    //================================
    //##### Async/Await #####
    func deleteStatistics(identifier: String) async throws {
        
        // Target Table
        let collectionRef = fs.collection("Stat")
        
        do {
            let response = try await collectionRef.whereField("stat_user_id", isEqualTo: identifier).getDocuments()
        
            // Exception Handling : Search Error
            guard response.documents.count == 1 else {
                if response.documents.count > 1 {
                    throw StaticErrorFS.MultipleStatFound
                } else {
                    throw StaticErrorFS.StatRetrievalByIdentifierFailed
                }
            }
            // Fetch Document
            guard let docs = response.documents.first else {
                throw StaticErrorFS.UnexpectedFetchError
            }
            
            // Delete Statistics
            try await docs.reference.delete()
            
        } catch {
            // Exception Handling : Internal Error (FirestoreServer)
            print("(Firestore) Error Delete Statistics : \(error)")
            throw StaticErrorFS.InternalError
        }
    }
}

//================================
// MARK: - Exception
//================================
enum StaticErrorFS: LocalizedError {
    case UnexpectedSetError
    case UnexpectedGetError
    case UnexpectedUpdateError
    case UnexpectedDeleteError
    case UnexpectedConvertError
    case UnexpectedFetchError
    case StatRetrievalByIdentifierFailed
    case MultipleStatFound
    case InternalError
    
    var errorDescription: String? {
        switch self {
        case .UnexpectedGetError:
            return "Firestore: There was an unexpected error while Get 'Statistics' details"
        case .UnexpectedSetError:
            return "Firestore: There was an unexpected error while Set 'Statistics' details"
        case .UnexpectedUpdateError:
            return "Firestore: There was an unexpected error while Update 'Statistics' details"
        case .UnexpectedDeleteError:
            return "Firestore: There was an unexpected error while Delete 'Statistics' details"
        case .UnexpectedConvertError:
            return "Firestore: There was an unexpected error while Convert 'Statistics' details"
        case .UnexpectedFetchError:
            return "Firestore: There was an unexpected error while Fetch 'Statistics' details"
        case .StatRetrievalByIdentifierFailed:
            return "Firestore: Unable to retrieve 'Statistics' data using the provided identifier."
        case .MultipleStatFound:
            return "Firestore: Multiple 'Statistics' found. Expected only one."
        case .InternalError:
            return "Firestore: Internal Error Occurred while process 'Statistics' details"
        }
    }
}
