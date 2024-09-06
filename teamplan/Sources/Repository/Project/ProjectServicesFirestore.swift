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

//MARK: Main

final class ProjectServicesFirestore: ProjectDocsManage {
    typealias Object = ProjectObject
    
    // set
    func setDocs(with objects: [ProjectObject], and userId: String, and batch: WriteBatch) async throws {
        let collectionRef = fetchSecondaryCollection(
            with: userId,
            primary: .project,
            secondary: .info
        )
        for object in objects {
            let data = convertToData(with: object)
            let docsRef = collectionRef.document(String(object.projectId))
            
            batch.setData(data, forDocument: docsRef)
        }
    }
    
    // get
    func getDocs(with projectId: Int, and userId: String) async throws -> Object {
        let data = try await getData(with: projectId, and: userId)
        return try convertToObject(with: data)
    }
    
    func getDocsList(with userId: String) async throws -> [Object] {
        let snapshotList = try await getSnapshotList(with: userId)
        return try snapshotList.compactMap{ try convertToObject(with: $0.data()) }
    }
    
    // delete
    func deleteDocs(with userId: String, and batch: WriteBatch) async throws {
        let docsList = try await fetchSecondaryCollection(
            with: userId,
            primary: .project,
            secondary: .info
        ).getDocuments().documents
        
        for docs in docsList {
            batch.deleteDocument(docs.reference)
        }
    }
}

//MARK: Sub

extension ProjectServicesFirestore {
    
    func getDocsRef(with projectId: Int, and userId: String) async -> DocumentReference {
        return fetchSecondaryCollection(
            with: userId,
            primary: .project,
            secondary: .info
        ).document(String(projectId))
    }
    
    func getDocsRefList(with projectIds: [Int], and userId: String) async -> [Int : DocumentReference] {
        var docsRefs: [Int : DocumentReference] = [:]
        let collectionRef = fetchSecondaryCollection(
            with: userId,
            primary: .project,
            secondary: .info
        )
        for projectId in projectIds {
            docsRefs[projectId] = collectionRef.document(String(projectId))
        }
        return docsRefs
    }
    
    func getSnapshot(with userId: String) async throws -> [QueryDocumentSnapshot] {
        return try await getSnapshotList(with: userId)
    }
    
    func getData(with projectId: Int, and userId: String) async throws -> [String:Any] {
        let docsRef = await getDocsRef(with: projectId, and: userId)
        guard let data = try await docsRef.getDocument().data() else {
            throw FirestoreError.fetchFailure(serviceName: .fs, dataType: .project)
        }
        return data
    }
    
    func checkUpdate(from serverData: ProjectObject, to localData: ProjectObject, at syncDate: Date) -> [String:Any] {
        var updatedData = [String: Any]()

        if serverData.title != localData.title {
            updatedData["title"] = localData.title
        }
        if serverData.status != localData.status {
            updatedData["status"] = localData.status.rawValue
        }
        if serverData.totalRegistedTodo != localData.totalRegistedTodo {
            updatedData["total_registed_todo"] = localData.totalRegistedTodo
        }
        if serverData.finishedTodo != localData.finishedTodo {
            updatedData["finished_todo"] = localData.finishedTodo
        }
        if serverData.alerted != localData.alerted {
            updatedData["alerted"] = localData.alerted
        }
        if serverData.extendedCount != localData.extendedCount {
            updatedData["extended_count"] = localData.extendedCount
        }
        if serverData.deadline != localData.deadline {
            updatedData["deadline"] = DateFormatter.standardFormatter.string(from: localData.deadline)
        }
        if serverData.finishedAt != localData.finishedAt {
            updatedData["finished_at"] = DateFormatter.standardFormatter.string(from: localData.finishedAt)
        }
        updatedData["synced_at"] = DateFormatter.standardFormatter.string(from: syncDate)

        return updatedData
    }
}
    
//MARK: Util

extension ProjectServicesFirestore {
    
    private func getSnapshotList(with userId: String) async throws -> [QueryDocumentSnapshot] {
        let collectionRef = fetchSecondaryCollection(
            with: userId,
            primary: .project,
            secondary: .info
        )
        
        async let ongoingSnapshot = collectionRef
            .whereField("user_id", isEqualTo: userId)
            .whereField("status", isEqualTo: ProjectStatus.ongoing.rawValue)
            .getDocuments()
        
        let ongoingResults = try await ongoingSnapshot
        return ongoingResults.documents
    }
    
    func convertToData(with object: Object) -> [String:Any] {
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
    
    func convertToObject(with data: [String: Any]) throws -> ProjectObject {
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
            throw FirestoreError.convertFailure(serviceName: .fs, dataType: .project)
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
