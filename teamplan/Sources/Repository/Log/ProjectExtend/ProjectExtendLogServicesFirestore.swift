//
//  ProjectExtendLogServicesFirestore.swift
//  teamplan
//
//  Created by 크로스벨 on 6/18/24.
//  Copyright © 2024 team1os. All rights reserved.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

//MARK: Main

final class ProjectExtendLogServicesFirestore: ExtendLogDocsManage {
    typealias Object = ProjectExtendLog
    
    func setDocs(with objectList: [ProjectExtendLog], and batch: WriteBatch) async {
        for object in objectList {
            let data = convertToData(with: object)
            let docsId = "\(object.projectId)_\(object.extendCount)"
            let docsRef = fetchSecondaryCollection(
                with: object.userId,
                primary: .project,
                secondary: .extendLog
            ).document(docsId)
            batch.setData(data, forDocument: docsRef, merge: true)
        }
    }
    
    func getDocs(with userId: String, and projectList: [Int]) async throws -> [Object] {
        var objectList = [Object]()
        let collectionRef = fetchSecondaryCollection(
            with: userId,
            primary: .project,
            secondary: .extendLog
        )
        for projectId in projectList {
            let docsRef = collectionRef.document(String(projectId))
            let snapshot = try await docsRef.getDocument()
            
            guard let data = snapshot.data() else {
                throw FirestoreError.fetchFailure(serviceName: .fs, dataType: .aclog)
            }
            objectList.append(try convertToObject(with: data, and: userId))
        }
        return objectList
    }
    
    func deleteDocs(with userId: String, and batch: WriteBatch) async throws {
        let docsList = try await fetchSecondaryCollection(
            with: userId,
            primary: .project,
            secondary: .extendLog
        ).getDocuments().documents
        
        for docs in docsList {
            batch.deleteDocument(docs.reference)
        }
    }
}

// MARK: - Util

extension ProjectExtendLogServicesFirestore {

    func convertToData(with object: Object) -> [String: Any] {
        let stringExtendAt = DateFormatter.shortFormatter.string(from: object.extendAt)
        let stringNewDeadline = DateFormatter.shortFormatter.string(from: object.newDeadline)
        
        return [
            "project_id": object.projectId,
            "extend_count": object.extendCount,
            "used_drop": object.usedDrop,
            "stored_drop": object.storedDrop,
            "extend_period": object.extendPeriod,
            "extend_at": stringExtendAt,
            "new_deadline": stringNewDeadline,
            "total_registed_todo": object.totalRegistedTodo,
            "total_finished_todo": object.totalFinshedTodo
        ]
    }
    
    private func convertToObject(with data: [String: Any], and userId: String) throws -> Object {
        guard let projectId = data["project_id"] as? Int,
              let extendCount = data["extend_count"] as? Int,
              let usedDrop = data["used_drop"] as? Int,
              let storedDrop = data["stored_drop"] as? Int,
              let extendPeriod = data["extend_period"] as? Int,
              let stringExtendAt = data["extend_at"] as? String,
              let extendAt = DateFormatter.standardFormatter.date(from: stringExtendAt),
              let stringNewDeadline = data["new_deadline"] as? String,
              let newDeadline = DateFormatter.standardFormatter.date(from: stringNewDeadline),
              let totalRegistedTodo = data["total_registed_todo"] as? Int,
              let totalFinishedTodo = data["total_finished_todo"] as? Int 
        else {
            throw FirestoreError.convertFailure(serviceName: .fs, dataType: .aclog)
        }
        
        return ProjectExtendLog(
            projectId: projectId,
            extendCount: extendCount,
            userId: userId,
            usedDrop: usedDrop,
            storedDrop: storedDrop,
            extendPeriod: extendPeriod,
            extendAt: extendAt,
            newDeadline: newDeadline,
            totalRegistedTodo: totalRegistedTodo,
            totalFinshedTodo: totalFinishedTodo
        )
    }
}
