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

final class AccessLogServicesFirestore: LogDocsManage {
    typealias Object = AccessLog
    
    func setDocs(with userId: String, and logHead: Int, and objects: [AccessLog]) async throws {
        let batch = Firestore.firestore().batch()
        let collectionRef = fetchCollection(with: .accessLog).document(userId).collection(String(logHead))
        
        for object in objects {
            let docsRef = collectionRef.document()
            batch.setData(convertToData(with: object), forDocument: docsRef)
        }
        try await batch.commit()
    }
    
    func getDocs(with userId: String, and logHead: Int) async throws -> [AccessLog] {
        let docs = try await fetchLogDocs(with: userId, and: .accessLog, and: logHead)
        return try docs.map { try convertToObject(with: $0.data()) }
    }
    
    func deleteDocs(with userId: String) async throws {
        let batch = Firestore.firestore().batch()
        let docs = try await fetchDocuments(with: userId, and: .accessLog)
        
        for doc in docs {
            batch.deleteDocument(doc.reference)
        }
        try await batch.commit()
    }
}

// MARK: - Converter
extension AccessLogServicesFirestore {
    private func convertToObject(with data: [String:Any]) throws -> AccessLog {
        guard let userId = data["user_id"] as? String,
              let stringAccessRecord = data["access_record"] as? String,
              let accessRecord = DateFormatter.standardFormatter.date(from: stringAccessRecord)
        else {
            throw FirestoreError.convertFailure(serviceName: .log)
        }
        return AccessLog(userId: userId, accessDate: accessRecord)
    }
    
    private func convertToData(with object: AccessLog) -> [String:Any] {
        return [
            "user_id": object.userId,
            "access_record": DateFormatter.standardFormatter.string(from: object.accessRecord)
        ]
    }
}

