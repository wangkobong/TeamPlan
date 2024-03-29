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

final class UserServicesFirestore: FullDocsManage {
    typealias Object = UserObject
    typealias DTO = UserUpdateDTO
    
    func setDocs(with object: UserObject) async throws {
        let collectionRef = fetchCollection(with: .user)
        try await collectionRef.addDocument(data: try convertToData(with: object))
    }
    
    func getDocs(with userId: String) async throws -> UserObject {
        guard let docs = try await fetchDocument(with: userId, and: .user),
              let data = docs.data() else {
            throw FirestoreError.fetchFailure(serviceName: .user)
        }
        return try convertToObject(with: data)
    }
    
    func updateDocs(with object: Object) async throws {
        guard let docs = try await fetchDocument(with: object.userId, and: .user) else {
            throw FirestoreError.fetchFailure(serviceName: .user)
        }
        try await docs.reference.updateData(try convertToData(with: object))
    }
    
    func deleteDocs(with userId: String) async throws {
        guard let docs = try await fetchDocument(with: userId, and: .user) else {
            throw FirestoreError.fetchFailure(serviceName: .user)
        }
        try await docs.reference.delete()
    }
}

// MARK: - Converter
extension UserServicesFirestore{
    
    private func convertToData(with object: Object) throws -> [String: Any] {
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
            throw FirestoreError.convertFailure(serviceName: .user)
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

