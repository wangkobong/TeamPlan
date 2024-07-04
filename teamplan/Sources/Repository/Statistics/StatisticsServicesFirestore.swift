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

//MARK: Main

final class StatisticsServicesFirestore: StatDocsManage {
    typealias Object = StatisticsObject
    typealias DTO = StatUpdateDTO
    
    func setDocs(with object: StatisticsObject, and batch: WriteBatch) async throws {
        let data = try convertToData(with: object)
        let docsRef = fetchPrimaryCollection(type: .stat).document(object.userId)
        batch.setData(data, forDocument: docsRef)
    }

    func getDocs(with userId: String) async throws -> Object {
        let data = try await getData(with: userId)
        return try convertToObject(with: data)
    }
    
    func deleteDocs(with userId: String, and batch: WriteBatch) async {
        let docsRef = await getDocsRef(with: userId)
        batch.deleteDocument(docsRef)
    }
}

// MARK: - Sub

extension StatisticsServicesFirestore {
    
    func getDocsRef(with userId: String) async -> DocumentReference {
        return fetchPrimaryCollection(type: .stat).document(userId)
    }
    
    func getData(with userId: String) async throws -> [String:Any] {
        let docsRef =  await getDocsRef(with: userId)
        guard let data = try await docsRef.getDocument().data() else {
            throw FirestoreError.fetchFailure(serviceName: .fs, dataType: .stat)
        }
        return data
    }
    
    func checkUpdate(from serverData: StatisticsObject, to localData: StatisticsObject, at syncDate: Date) async throws -> [String:Any] {
        let util = Utilities()
        var updatedData = [String: Any]()
        
        if serverData.term != localData.term {
            updatedData["term"] = localData.term
        }
        if serverData.drop != localData.drop {
            updatedData["drop"] = localData.drop
        }
        if serverData.totalRegistedProjects != localData.totalRegistedProjects {
            updatedData["total_registed_projects"] = localData.totalRegistedProjects
        }
        if serverData.totalFinishedProjects != localData.totalFinishedProjects {
            updatedData["total_finished_projects"] = localData.totalFinishedProjects
        }
        if serverData.totalFailedProjects != localData.totalFailedProjects {
            updatedData["total_failed_projects"] = localData.totalFailedProjects
        }
        if serverData.totalAlertedProjects != localData.totalAlertedProjects {
            updatedData["total_alerted_projects"] = localData.totalAlertedProjects
        }
        if serverData.totalExtendedProjects != localData.totalExtendedProjects {
            updatedData["total_extended_projects"] = localData.totalExtendedProjects
        }
        if serverData.totalRegistedTodos != localData.totalRegistedTodos {
            updatedData["total_registed_todos"] = localData.totalRegistedTodos
        }
        if serverData.totalFinishedTodos != localData.totalFinishedTodos {
            updatedData["total_finished_todos"] = localData.totalFinishedTodos
        }
        if serverData.challengeStepStatus != localData.challengeStepStatus {
            let challengeStepStatus = localData.challengeStepStatus.mapKeys{ String($0) }
            updatedData["challenge_step_status"] = challengeStepStatus
        }
        if serverData.mychallenges != localData.mychallenges {
            updatedData["mychallenges"] = localData.mychallenges
        }
        updatedData["synced_at"] = DateFormatter.standardFormatter.string(from: syncDate)
       
        
        return updatedData
    }
}

// MARK: - Util

extension StatisticsServicesFirestore {
    
    func convertToData(with object: Object) throws -> [String: Any] {
        let stringSyncedAt = DateFormatter.standardFormatter.string(from: object.syncedAt)
        let challengeStepStatus = object.challengeStepStatus.mapKeys{ String($0) }
        
        return [
            "user_id": object.userId,
            "term": object.term,
            "drop": object.drop,
            "total_registed_projects": object.totalRegistedProjects,
            "total_finished_projects": object.totalFinishedProjects,
            "total_failed_projects": object.totalFailedProjects,
            "total_alerted_projects": object.totalAlertedProjects,
            "total_extended_projects": object.totalExtendedProjects,
            "total_registed_todos": object.totalRegistedTodos,
            "total_finished_todos": object.totalFinishedTodos,
            "challenge_step_status": challengeStepStatus,
            "mychallenges": object.mychallenges,
            "synced_at": stringSyncedAt
        ]
    }
    
    private func convertToObject(with data: [String: Any]) throws -> Object {
        guard let userId = data["user_id"] as? String,
              let term = data["term"] as? Int,
              let drop = data["drop"] as? Int,
              let totalRegistedProjects = data["total_registed_projects"] as? Int,
              let totalFinishedProjects = data["total_finished_projects"] as? Int,
              let totalFailedProjects = data["total_failed_projects"] as? Int,
              let totalAlertedProjects = data["total_alerted_projects"] as? Int,
              let totalExtendedProjects = data["total_extended_projects"] as? Int,
              let totalRegistedTodos = data["total_registed_todos"] as? Int,
              let totalFinishedTodos = data["total_finished_todos"] as? Int,
              let challengeStepStatusString = data["challenge_step_status"] as? [String : Int],
              let myChallenges = data["mychallenges"] as? [Int],
              let stringSyncedAt = data["synced_at"] as? String,
              let syncedAt = DateFormatter.standardFormatter.date(from: stringSyncedAt)
        else {
            throw FirestoreError.convertFailure(serviceName: .fs, dataType: .stat)
        }
        let challengeStepStatus: [Int: Int] = challengeStepStatusString.compactMapKeys { Int($0) }
        return Object(
            userId: userId,
            term: term,
            drop: drop,
            totalRegistedProjects: totalRegistedProjects,
            totalFinishedProjects: totalFinishedProjects,
            totalFailedProjects: totalFailedProjects,
            totalAlertedProjects: totalAlertedProjects,
            totalExtendedProjects: totalExtendedProjects,
            totalRegistedTodos: totalRegistedTodos,
            totalFinishedTodos: totalFinishedTodos,
            challengeStepStatus: challengeStepStatus,
            mychallenges: myChallenges,
            syncedAt: syncedAt
        )
    }
}
