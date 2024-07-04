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

//MARK: Main

final class UserServicesFirestore: UserDocsManage {
    typealias Object = UserObject
    typealias DTO = UserUpdateDTO

    func setDocs(with object: UserObject, and batch: WriteBatch) async {
        let data = convertToData(with: object)
        let docsRef = fetchSecondaryCollection(
            with: object.userId,
            primary: .user,
            secondary: .info
        ).document(object.userId)
        batch.setData(data, forDocument: docsRef)
    }
    
    func getDocs(with userId: String) async throws -> UserObject {
        let data = try await getData(with: userId)
        return try convertToObject(with: data)
    }
    
    // delete
    func deleteDocs(with userId: String, and batch: WriteBatch) async {
        let docsRef = await getDocsRef(with: userId)
        batch.deleteDocument(docsRef)
    }
}

//MARK: Sub

extension UserServicesFirestore {
    
    func getDocsRef(with userId: String) async -> DocumentReference {
        return fetchSecondaryCollection(
            with: userId,
            primary: .user,
            secondary: .info
        ).document(userId)
    }
    
    func getData(with userId: String) async throws -> [String:Any] {
        let docsRef = await getDocsRef(with: userId)
        guard let data = try await docsRef.getDocument().data() else {
            throw FirestoreError.fetchFailure(serviceName: .fs, dataType: .user)
        }
        return data
    }
    
    func checkUpdate(from serverData: UserObject, to localData: UserObject, or newLogHead: Int? = nil, at syncedDate: Date) async throws -> [String:Any] {
        var updatedData = [String: Any]()
        
        if let newLogHead = newLogHead {
            updatedData["access_log_head"] = newLogHead
            return updatedData
        }
        
        if serverData.name != localData.name {
            updatedData["name"] = localData.name
        }
        
        if serverData.status != localData.status {
            updatedData["status"] = localData.status.rawValue
        }
        
        if serverData.changedAt != localData.changedAt {
            let stringChangedAt = DateFormatter.standardFormatter.string(from: localData.changedAt)
            updatedData["changed_at"] = stringChangedAt
        }
        
        if serverData.accessLogHead != localData.accessLogHead {
            updatedData["access_log_head"] = localData.accessLogHead
        }
        updatedData["synced_at"] = DateFormatter.standardFormatter.string(from: syncedDate)
        
        return updatedData
    }
}

// MARK: - Util

extension UserServicesFirestore {
    
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
