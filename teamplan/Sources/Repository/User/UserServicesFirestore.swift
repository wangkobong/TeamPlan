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

// MARK: Main

final class UserServicesFirestore {
    typealias Object = UserObject
    typealias DTO = UserUpdateDTO

    private let manager = DocsManager.shared
    private var object = UserObject()
    private var data: [String: Any] = [:]
    init() {}
    
    func setDocs(with object: UserObject, and batch: WriteBatch) -> Bool {
        guard let serverId = object.serverId,
              convertToData(with: object, and: serverId) else {
            print("[UserServerRepo] Failed to convert object to data format")
            return false
        }
        let docsRef = manager.fetchSecondaryCollection(
            with: serverId,
            primary: .user,
            secondary: .info
        ).document(object.userId)
        
        batch.setData(self.data, forDocument: docsRef)
        return true
    }
    
    func prepareDocs(with serverId: String, and userId: String) async -> Bool {
        if await getData(with: serverId, and: userId) {
            return convertToObject(with: self.data, and: serverId)
        } else {
            return false
        }
    }
    
    func getDocsData() -> Object {
        return self.object
    }
    
    func deleteDocs(with serverId: String, and userId: String, batch: WriteBatch) {
        let docsRef = manager.fetchSecondaryCollection(
            with: serverId,
            primary: .user,
            secondary: .info
        ).document(userId)
        
        batch.deleteDocument(docsRef)
    }
}

// MARK: Sub

extension UserServicesFirestore {
    
    func getData(with serverId: String, and userId: String) async -> Bool {
        guard let docs = await manager.fetchSecondaryDocs(
            with: serverId,
            secondaryId: userId,
            primary: .user,
            secondary: .info),
              let data = docs.data() else {
            print("[UserServerRepo] Failed to get data from document")
            return false
        }
        self.data = data
        return true
    }
}

// MARK: - Util

extension UserServicesFirestore {
    
    func convertToData(with object: Object, and serverId: String) -> Bool {
        guard let email = object.email,
              let socialType = object.socialType,
              let syncedAt = object.syncedAt else {
            print("[UserServerRepo] Failed to convert object to data format")
            return false
        }
        
        let formatter = DateFormatter.standardFormatter
        self.data = [
            "user_id": object.userId,
            "name": object.name,
            "user_status": object.userStatus.rawValue,
            "access_log_head": object.accessLogHead,
            "created_at": formatter.string(from: object.createdAt),
            "online_status": object.onlineStatus,
            "changed_at": formatter.string(from: object.changedAt),
            "server_id": serverId,
            "email": email,
            "social_type": socialType.rawValue,
            "synced_at": formatter.string(from: syncedAt)
        ]
        return true
    }
    
    private func convertToObject(with data: [String: Any], and docsId: String) -> Bool {
        guard let userId = data["user_id"] as? String,
              let name = data["name"] as? String,
              let stringUserStatus = data["user_status"] as? String,
              let userStatus = UserStatus(rawValue: stringUserStatus),
              let accessLogHead = data["access_log_head"] as? Int,
              let stringCreatedAt = data["created_at"] as? String,
              let createdAt = DateFormatter.standardFormatter.date(from: stringCreatedAt),
              let onlineStatus = data["online_status"] as? Bool,
              let stringChangedAt = data["changed_at"] as? String,
              let changedAt = DateFormatter.standardFormatter.date(from: stringChangedAt),
              let email = data["email"] as? String,
              let stringSocialType = data["social_type"] as? String,
              let socialType = Providers(rawValue: stringSocialType),
              let stringSyncedAt = data["synced_at"] as? String,
              let syncedAt = DateFormatter.standardFormatter.date(from: stringSyncedAt) else {
            print("[UserServerRepo] Failed to convert data to object format")
            return false
        }
        
        self.object = UserObject(
            userId: userId,
            name: name,
            userStatus: userStatus,
            accessLogHead: accessLogHead,
            createdAt: createdAt,
            onlineStatus: onlineStatus,
            changedAt: changedAt,
            serverId: docsId,
            email: email,
            socialType: socialType,
            syncedAt: syncedAt
        )
        return true
    }
}
