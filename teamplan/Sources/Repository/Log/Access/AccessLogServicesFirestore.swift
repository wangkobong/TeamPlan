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

//MARK: Main

final class AccessLogServicesFirestore: AccessLogDocsManage {
    typealias Object = AccessLog
    
    func setDocs(with userId: String, and logHead: Int, and objects: [AccessLog], and batch: WriteBatch) async {
        let data = await convertToData(with: userId, and: objects)
        let docsRef = fetchSecondaryCollection(
            with: userId,
            primary: .user,
            secondary: .accessLog
        ).document(String(logHead))
        batch.setData(data, forDocument: docsRef)
    }
    
    func getDocs(with userId: String, and logHead: Int) async throws -> [AccessLog] {
        let docsRef = await getDocsRef(with: userId, and: logHead)
        let snapshot = try await docsRef.getDocument()
        
        guard let data = snapshot.data() else {
            throw FirestoreError.fetchFailure(serviceName: .fs, dataType: .log)
        }
        return try convertToObject(with: data)
    }
    
    func deleteDocs(with userId: String, and batch: WriteBatch) async throws {
        let docsList = try await fetchSecondaryCollection(
            with: userId,
            primary: .user,
            secondary: .accessLog
        ).getDocuments().documents

        for docs in docsList {
            batch.deleteDocument(docs.reference)
        }
    }
}

// MARK: - Sub
extension AccessLogServicesFirestore {
    
    func getDocsRef(with userId: String, and logHead: Int) async -> DocumentReference {
        return fetchSecondaryCollection(
            with: userId,
            primary: .user,
            secondary: .accessLog
        ).document(String(logHead))
    }
    
    func checkUpdate(with localData: [AccessLog]) async -> [String:Any] {
        let log = localData.map { DateFormatter.standardFormatter.string(from: $0.accessRecord) }
        return [
            "record" : log
        ]
    }
}

// MARK: - Util

extension AccessLogServicesFirestore {
    
    func convertToData(with userId: String, and objectList: [AccessLog]) async -> [String:Any] {
        let log = objectList.map { DateFormatter.standardFormatter.string(from: $0.accessRecord) }
        return [
            "user_id": userId,
            "record": log
        ]
    }
    
    private func convertToObject(with data: [String: Any]) throws -> [AccessLog] {
        guard let userId = data["user_id"] as? String,
              let stringAccessRecord = data["record"] as? [String] else {
            throw FirestoreError.convertFailure(serviceName: .fs, dataType: .log)
        }
        
        let logList: [AccessLog] = try stringAccessRecord.map { stringRecord in
            guard let record = DateFormatter.standardFormatter.date(from: stringRecord) else {
                throw FirestoreError.convertFailure(serviceName: .fs, dataType: .log)
            }
            return AccessLog(userId: userId, accessDate: record)
        }
        return logList
    }
}

