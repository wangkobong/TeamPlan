//
//  ProjectServicesFirestore.swift
//  teamplan
//
//  Created by 크로스벨 on 3/27/24.
//  Copyright © 2024 team1os. All rights reserved.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

final class ProjectServicesFirestore: ProjectDocsManage {
    typealias Object = ProjectObject
    
    func setDocs(with objects: [ProjectObject], and userId: String) async throws {
        let batch = getFirestoreInstance().batch()
        let collectionRef = fetchCollection(with: .project).document(userId).collection(CollectionType.project.rawValue)
        
        for object in objects {
            let docsRef = collectionRef.document(String(object.projectId))
            batch.setData(convertToData(with: object), forDocument: docsRef)
        }
        try await batch.commit()
    }
    
    func getDocs(with userId: String) async throws -> [ProjectObject] {
        let docs = try await fetchDocuments(with: userId, and: .project)
        return try docs.map { try convertToObject(with: $0.data()) }
    }
    
    func getDocs(with projectId: Int, and userId: String) async throws -> ProjectObject {
        let docs = try await fetchProjectDocs(userId: userId, type: .project, projectId: projectId)
        guard let data = docs.data() else {
            throw FirestoreError.fetchFailure(serviceName: .project)
        }
        return try convertToObject(with: data)
    }
    
    func updateDocs(with objects: [Object], and userId: String) async throws {
        let batch = getFirestoreInstance().batch()
        let collectionRef = fetchCollection(with: .project).document(userId).collection(CollectionType.project.rawValue)
        
        for object in objects {
            let docsRef = collectionRef.document(String(object.projectId))
            batch.updateData(convertToData(with: object), forDocument: docsRef)
        }
        try await batch.commit()
    }
    
    func deleteDocs(with projectId: Int, and userId: String) async throws {
        let docs = fetchCollection(with: .project).document(userId).collection(CollectionType.project.rawValue).document(String(projectId))
        try await docs.delete()
    }
}

// Converter
extension ProjectServicesFirestore {
    
    private func convertToData(with object: Object) -> [String:Any] {
        let stringRegistedAt = DateFormatter.standardFormatter.string(from: object.registedAt)
        let stringStartedAt = DateFormatter.standardFormatter.string(from: object.startedAt)
        let stringDeadline = DateFormatter.standardFormatter.string(from: object.deadline)
        let stringFinishedAt = DateFormatter.standardFormatter.string(from: object.finishedAt)
        let stringSyncedAt = DateFormatter.standardFormatter.string(from: object.syncedAt)
        
        return [
            "project_id": object.projectId,
            "user_id": object.userId,
            "title": object.title,
            "status": object.status.rawValue,
            "total_registed_todo": object.totalRegistedTodo,
            "daily_registed_todo": object.dailyRegistedTodo,
            "finished_todo": object.finishedTodo,
            "alerted": object.alerted,
            "extended_count": object.extendedCount,
            "registed_at": stringRegistedAt,
            "started_at": stringStartedAt,
            "deadline": stringDeadline,
            "finished_at": stringFinishedAt,
            "synced_at": stringSyncedAt
        ]
    }
    
    private func convertToObject(with data: [String: Any]) throws -> ProjectObject {
        guard let projectId = data["project_id"] as? Int,
              let userId = data["user_id"] as? String,
              let title = data["title"] as? String,
              let rawStatus = data["status"] as? Int,
              let status = ProjectStatus(rawValue: rawStatus),
              let totalRegistedTodo = data["total_registed_todo"] as? Int,
              let dailyRegistedTodo = data["daily_registed_todo"] as? Int,
              let finishedTodo = data["finished_todo"] as? Int,
              let alerted = data["alerted"] as? Int,
              let extendedCount = data["extended_count"] as? Int,
              let stringRegistedAt = data["registed_at"] as? String,
              let registedAt = DateFormatter.standardFormatter.date(from: stringRegistedAt),
              let stringStartedAt = data["started_at"] as? String,
              let startedAt = DateFormatter.standardFormatter.date(from: stringStartedAt),
              let stringDeadline = data["deadline"] as? String,
              let deadline = DateFormatter.standardFormatter.date(from: stringDeadline),
              let stringFinishedAt = data["finished_at"] as? String,
              let finishedAt = DateFormatter.standardFormatter.date(from: stringFinishedAt),
              let stringSyncedAt = data["synced_at"] as? String,
              let syncedAt = DateFormatter.standardFormatter.date(from: stringSyncedAt)
        else {
            throw FirestoreError.convertFailure(serviceName: .project)
        }
        return ProjectObject(
            projectId: projectId,
            userId: userId,
            title: title,
            status: status,
            todos: [],
            totalRegistedTodo: totalRegistedTodo,
            dailyRegistedTodo: dailyRegistedTodo,
            finishedTodo: finishedTodo,
            alerted: alerted,
            extendedCount: extendedCount,
            registedAt: registedAt,
            startedAt: startedAt,
            deadline: deadline,
            finishedAt: finishedAt,
            syncedAt: syncedAt
        )
    }
}
