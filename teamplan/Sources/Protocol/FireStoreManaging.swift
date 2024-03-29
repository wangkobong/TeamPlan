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

// MARK: - Basic
enum CollectionType: String {
    case user = "User"
    case stat = "Stat"
    case coreValue = "CoreValue"
    case challengeInfo = "Challenge"
    case challengeStatus = "ChallengeStatus"
    case project = "Project"
    case accessLog = "AccessLog"
}

extension BasicDocsManage {
    func getFirestoreInstance() -> Firestore {
        return Firestore.firestore()
    }
    
    func fetchCollection(with type: CollectionType) -> CollectionReference {
        return getFirestoreInstance().collection(type.rawValue)
    }
    
    func fetchDocument(with userId: String, and type: CollectionType) async throws -> DocumentSnapshot? {
        let query = getFirestoreInstance().collection(type.rawValue).whereField("user_id", isEqualTo: userId)
        let snapshot = try await query.getDocuments()
        return snapshot.documents.first
    }
    
    func fetchDocuments(with userId: String, and type: CollectionType) async throws -> [QueryDocumentSnapshot] {
        let query = getFirestoreInstance().collection(type.rawValue).document(userId).collection(type.rawValue)
        return try await query.getDocuments().documents
    }
    
    func fetchProjectDocs(userId: String, type: CollectionType, projectId: Int) async throws -> DocumentSnapshot {
        let query = getFirestoreInstance().collection(type.rawValue).document(userId)
            .collection(type.rawValue).document(String(projectId))
        return try await query.getDocument()
    }
    
    func fetchChallengeDocs(with type: CollectionType) async throws -> [QueryDocumentSnapshot] {
        let query = getFirestoreInstance().collection(type.rawValue)
        return try await query.getDocuments().documents
    }
    
    func fetchLogDocs(with userId: String, and type: CollectionType, and logHead: Int) async throws -> [QueryDocumentSnapshot] {
        let query = getFirestoreInstance().collection(type.rawValue).document(userId).collection(String(logHead))
        return try await query.getDocuments().documents
    }
}

// MARK: - ReadOnly
protocol ReadOnlyDocsManage: BasicDocsManage {
    
    func getFirestoreInstance() -> Firestore
    func getDocs(with userId: String) async throws -> Object
}

// MARK: - Full
protocol FullDocsManage: ReadOnlyDocsManage {
    
    func setDocs(with object: Object) async throws
    func updateDocs(with object: Object) async throws
    func deleteDocs(with userId: String) async throws
}

// MARK: - Challenge
protocol ChallengeDocsManage: BasicDocsManage {
    associatedtype infoDTO
    associatedtype statusDTO
    
    func setDocs(with objects: [Object], and userId: String) async throws
    func getInfoDocsList() async throws -> [infoDTO]
    func getStatusDocsList(with userId: String) async throws -> [statusDTO]
    func updateDocs(with objects: [Object], and userId: String) async throws
    func deleteDocs(with userId: String) async throws
}

// MARK: - Log
protocol LogDocsManage: BasicDocsManage {
    
    func setDocs(with userId: String, and logHead: Int, and objects: [Object]) async throws
    func getDocs(with userId: String, and logHead: Int) async throws -> [Object]
    func deleteDocs(with userId: String) async throws
}

// MARK: - Project
protocol ProjectDocsManage: BasicDocsManage {
    
    func setDocs(with objects: [Object], and userId: String) async throws
    func getDocs(with userId: String) async throws -> [Object]
    func getDocs(with projectId: Int, and userId: String) async throws -> Object
    func updateDocs(with objects: [Object], and userId: String) async throws
    func deleteDocs(with projectId: Int, and userId: String) async throws
}

