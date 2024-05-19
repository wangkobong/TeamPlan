//
//  UserServicesFirestore.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/08/24.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

final class UserServicesFirestore: SingleDocsManage {
    typealias Object = UserObject
    typealias DTO = UserUpdateDTO
    
    func setDocs(with object: UserObject) async throws {
        let docsRef = fetchCollection(with: .user).document(object.userId)
        try await docsRef.setData(convertToData(with: object))
    }
    
    func getDocs(with userId: String) async throws -> UserObject {
        guard let data = try await fetchDocsSnapshot(with: userId, and: .user).data() else {
            throw FirestoreError.fetchFailure(serviceName: .fs, dataType: .user)
        }
        return try convertToObject(with: data)
    }
    
    func deleteDocs(with userId: String) async throws {
        let docsRef = try await fetchDocsReference(with: userId, and: .user)
        try await docsRef.delete()
    }
    
    func convertToData(with object: Object) -> [String: Any] {
        let stringCreatedAt = DateFormatter.standardFormatter.string(from: object.createdAt)
        let stringChangedAt = DateFormatter.standardFormatter.string(from: object.changedAt)
        let stringSyncedAt = DateFormatter.standardFormatter.string(from: object.syncedAt)
        
        return [
            "user_id": object.userId,
            "email": object.email,
            "name": object.name,
            "social_type": object.socialType.rawValue,
            "status": object.status.rawValue,
            "access_log_head": object.accessLogHead,
            "created_at": stringCreatedAt,
            "changed_at": stringChangedAt,
            "synced_at": stringSyncedAt
        ]
    }
}

// MARK: - Converter
extension UserServicesFirestore{
    
    private func convertToObject(with data: [String: Any]) throws -> UserObject {
        guard let userId = data["user_id"] as? String,
              let email = data["email"] as? String,
              let name = data["name"] as? String,
              let stringSocialType = data["social_type"] as? String,
              let socialType = Providers(rawValue: stringSocialType),
              let stringStatus = data["status"] as? String,
              let status = UserStatus(rawValue: stringStatus),
              let accessLogHead = data["access_log_head"] as? Int,
              let stringCreatedAt = data["created_at"] as? String,
              let createdAt = DateFormatter.standardFormatter.date(from: stringCreatedAt),
              let stringChangedAt = data["changed_at"] as? String,
              let changedAt = DateFormatter.standardFormatter.date(from: stringChangedAt),
              let stringSyncedAt = data["synced_at"] as? String,
              let syncedAt = DateFormatter.standardFormatter.date(from: stringSyncedAt)
        else {
            throw FirestoreError.convertFailure(serviceName: .fs, dataType: .user)
        }
        return UserObject(
            userId: userId,
            email: email,
            name: name,
            socialType: socialType,
            status: status,
            accessLogHead: accessLogHead,
            createdAt: createdAt,
            changedAt: changedAt,
            syncedAt: syncedAt
        )
    }
}

