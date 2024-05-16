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

final class StatisticsServicesFirestore: SingleDocsManage {
    typealias Object = StatisticsObject
    typealias DTO = StatUpdateDTO
    
    func setDocs(with object: Object) async throws {
        let docsRef = fetchCollection(with: .stat).document(object.userId)
        try await docsRef.setData(try convertToData(with: object))
    }
    
    func getDocs(with userId: String) async throws -> Object {
        guard let data = try await fetchDocsSnapshot(with: userId, and: .stat).data() else {
            throw FirestoreError.fetchFailure(serviceName: .fs, dataType: .stat)
        }
        return try convertToObject(with: data)
    }

    func deleteDocs(with userId: String) async throws {
        let docsRef = try await fetchDocsReference(with: userId, and: .stat)
        try await docsRef.delete()
    }
    
    func convertToData(with object: Object) throws -> [String: Any] {
        let stringSyncedAt = DateFormatter.standardFormatter.string(from: object.syncedAt)
        let challengeStepStatus = try Utilities().convertToJSON(data: object.challengeStepStatus)
        let myChallenges = try Utilities().convertToJSON(data: object.mychallenges)
        
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
            "mychallenges": myChallenges,
            "synced_at": stringSyncedAt
        ]
    }
}

// MARK: - Converter
extension StatisticsServicesFirestore {
    
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
              let challengeStepStatusString = data["challenge_step_status"] as? String,
              let myChallengesString = data["mychallenges"] as? String,
              let stringSyncedAt = data["synced_at"] as? String,
              let syncedAt = DateFormatter.standardFormatter.date(from: stringSyncedAt)
        else {
            throw FirestoreError.convertFailure(serviceName: .fs, dataType: .stat)
        }
        
        let challengeStepStatus = try Utilities().convertFromJSON(jsonString: challengeStepStatusString, type: [Int: Int].self)
        let myChallenges = try Utilities().convertFromJSON(jsonString: myChallengesString, type: [Int].self)
        
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
