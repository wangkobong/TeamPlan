//
//  DocsManageProtocol.swift
//  teamplan
//
//  Created by 크로스벨 on 3/22/24.
//  Copyright © 2024 team1os. All rights reserved.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

protocol BasicDocsManage {
    associatedtype Object
    
    func getFirestoreInstance() -> Firestore
}

// MARK: Docs Reference

enum PrimaryCollection: String {
    case user = "User"
    case stat = "Stat"
    case coreValue = "CoreValue"
    case challenge = "Challenge"
    case project = "Project"
}

enum SecondaryCollection: String {
    // Shared
    case info = "Info"
    
    // User
    case accessLog = "AccessLog"
    case challengeStatus = "ChallengeStatus"
    
    // Project
    case todoLog = "TodoLog"
    case extendLog = "ExtendLog"
}

enum CollectionType: String {
    case user = "User"
    case stat = "Stat"
    case coreValue = "CoreValue"
    case challengeInfo = "Challenge"
    case challengeStatus = "ChallengeStatus"
    case projectStatus = "ProjectStatus"
    case projectTodoLog = "TodoLog"
    case projectExtendLog = "ExtendLog"
    case accessLog = "AccessLog"
}

extension BasicDocsManage {
    
    func getFirestoreInstance() -> Firestore {
        return Firestore.firestore()
    }
    
    // Collection
    func fetchPrimaryCollection(type: PrimaryCollection) -> CollectionReference {
        return getFirestoreInstance().collection(type.rawValue)
    }
    
    func fetchSecondaryCollection(with userId: String, primary: PrimaryCollection, secondary: SecondaryCollection) -> CollectionReference {
        switch primary {
        case .stat, .coreValue, .challenge:
            return fetchPrimaryCollection(type: primary)
        case .user, .project:
            return getFirestoreInstance()
                .collection(primary.rawValue)
                .document(userId)
                .collection(secondary.rawValue)
        }
    }
    
    // Documents
    func fetchPrimaryDocs(with userId: String, primary: PrimaryCollection) async throws -> DocumentSnapshot {
        let requestQuery = fetchPrimaryCollection(type: primary).document(userId)
        return try await requestQuery.getDocument()
    }
    
    func fetchSecondaryDocs(with userId: String, secondaryId: Int, primary: PrimaryCollection, secondary: SecondaryCollection) async throws -> DocumentSnapshot {
        let requestQuery = fetchSecondaryCollection(with: userId, primary: primary, secondary: secondary).document(String(secondaryId))
        return try await requestQuery.getDocument()
    }
}

//MARK: Protocol

protocol UserDocsManage: BasicDocsManage {
    func setDocs(with object: Object, and batch: WriteBatch) async
    func getDocs(with userId: String) async throws -> Object
    func deleteDocs(with userId: String, and batch: WriteBatch) async
}

protocol StatDocsManage: BasicDocsManage {
    func setDocs(with object: Object, and batch: WriteBatch) async throws
    func getDocs(with userId: String) async throws -> Object
    func deleteDocs(with userId: String, and batch: WriteBatch) async
}

protocol ChallengeDocsManage: BasicDocsManage {
    associatedtype infoDTO
    associatedtype statusDTO
    
    func setDocs(with objects: [Object], and userId: String, and batch: WriteBatch) async throws
    func getInfoDocsList() async throws -> [infoDTO]
    func getStatusDocsList(with userId: String) async throws -> [statusDTO]
    func deleteStatusDocs(with userId: String, and batch: WriteBatch) async throws
}

protocol ProjectDocsManage: BasicDocsManage {
    
    func setDocs(with objects: [ProjectObject], and userId: String, and batch: WriteBatch) async throws
    func getDocs(with projectId: Int, and userId: String) async throws -> Object
    func getDocsList(with userId: String) async throws -> [Object]
    func deleteDocs(with userId: String, and batch: WriteBatch) async throws
}

protocol AccessLogDocsManage: BasicDocsManage {
    
    func setDocs(with userId: String, and logHead: Int, and objects: [Object], and batch: WriteBatch) async throws
    func getDocs(with userId: String, and logHead: Int) async throws -> [Object]
    func deleteDocs(with userId: String, and batch: WriteBatch) async throws
}

protocol ExtendLogDocsManage: BasicDocsManage {
    
    func setDocs(with objectList: [Object], and batch: WriteBatch) async throws
    func getDocs(with userId: String, and projectList: [Int]) async throws -> [Object]
    func deleteDocs(with userId: String, and batch: WriteBatch) async throws
}
