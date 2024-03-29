//
//  CoreValueServicesFirestore.swift
//  teamplan
//
//  Created by 크로스벨 on 3/22/24.
//  Copyright © 2024 team1os. All rights reserved.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

final class CoreValueServicesFirestore: ReadOnlyDocsManage {
    typealias Object = CoreValueObject
    
    func getDocs(with userId: String) async throws -> CoreValueObject {
        guard let docs = try await fetchDocument(with: userId, and: .coreValue),
              let data = docs.data() else {
            throw FirestoreError.fetchFailure(serviceName: .coreValue)
        }
        return try convertToObject(with: data)
    }
}

extension CoreValueServicesFirestore {
    
    private func convertToObject(with data: [String:Any]) throws -> CoreValueObject {
        guard let userId = data["user_id"] as? String,
              let projectRegistLimit = data["project_limit"] as? Int,
              let todoRegistLimit = data["todo_limit"] as? Int,
              let dropRation = data["drop_ratio"] as? Float,
              let syncCycle = data["sync_cycle"] as? Int
        else {
            throw FirestoreError.convertFailure(serviceName: .coreValue)
        }
        return CoreValueObject(
            userId: userId,
            projectRegistLimit: projectRegistLimit,
            todoRegistLimit: todoRegistLimit,
            dropConvertRatio: dropRation,
            syncCycle: syncCycle
        )
    }
}
