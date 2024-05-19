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

final class CoreValueServicesFirestore: BasicDocsManage {
    typealias Object = CoreValueObject
    
    func getDocs(with userId: String) async throws -> CoreValueObject {
        guard let data = try await fetchDocument(with: .coreValue).data() else {
            throw FirestoreError.fetchFailure(serviceName: .fs, dataType: .coreValue)
        }
        return try convertToObject(with: userId, and: data)
    }
}

extension CoreValueServicesFirestore {
    
    private func convertToObject(with userId: String, and data: [String:Any]) throws -> CoreValueObject {
        guard let projectRegistLimit = data["project_limit"] as? Int,
              let todoRegistLimit = data["todo_limit"] as? Int,
              let dropRation = data["drop_ratio"] as? Float,
              let syncCycle = data["sync_cycle"] as? Int
        else {
            throw FirestoreError.convertFailure(serviceName: .fs, dataType: .coreValue)
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
