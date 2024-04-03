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
    
    func fetchDocument(with type: CollectionType) async throws -> DocumentSnapshot {
        let query = getFirestoreInstance()
            .collection(type.rawValue)
            .document(type.rawValue)
        return try await query.getDocument()
    }
    
    func fetchDocuments(with userId: String, and type: CollectionType) async throws -> [QueryDocumentSnapshot] {
        let query = getFirestoreInstance()
            .collection(type.rawValue)
            .document(userId)
            .collection(type.rawValue)
        return try await query.getDocuments().documents
    }
}

// MARK: - User, Stat
protocol SingleDocsManage: BasicDocsManage {
    
    func getDocs(with userId: String) async throws -> Object
    func setDocs(with object: Object) async throws
    func deleteDocs(with userId: String) async throws
}

extension SingleDocsManage {
    func fetchDocsSnapshot(with userId: String, and type: CollectionType) async throws -> DocumentSnapshot {
        let query = getFirestoreInstance()
            .collection(type.rawValue)
            .document(userId)
        return try await query.getDocument()
    }
    
    func fetchDocsReference(with userId: String, and type: CollectionType) async throws -> DocumentReference {
        return try await fetchDocsSnapshot(with: userId, and: type).reference
    }
}


// MARK: - Challenge
protocol ChallengeDocsManage: BasicDocsManage {
    associatedtype infoDTO
    associatedtype statusDTO
    
    func setDocs(with objects: [Object], and userId: String) async throws
    func getInfoDocsList() async throws -> [infoDTO]
    func getStatusDocsList(with userId: String) async throws -> [statusDTO]
    func deleteDocs(with userId: String) async throws
}


// MARK: - Log
protocol LogDocsManage: BasicDocsManage {
    
    func setDocs(with userId: String, and logHead: Int, and objects: [Object]) async throws
    func getDocs(with userId: String, and logHead: Int) async throws -> [Object]
    func deleteDocs(with userId: String, and logHead: Int) async throws
}

extension LogDocsManage {
    
    func fetchDocsSnapshot(with userId: String, and logHead: Int) async throws -> [QueryDocumentSnapshot] {
        let query = getFirestoreInstance()
            .collection(CollectionType.accessLog.rawValue)
            .document(userId)
            .collection(String(logHead))
        return try await query.getDocuments().documents
    }
    
    func fetchCollectionReference(with userId: String, and logHead: Int) -> CollectionReference {
        return getFirestoreInstance()
            .collection(CollectionType.accessLog.rawValue)
            .document(userId)
            .collection(String(logHead))
    }
}


// MARK: - Project
protocol ProjectDocsManage: BasicDocsManage {
    
    func setDocs(with objects: [Object], and userId: String) async throws
    func getDocs(with projectId: Int, and userId: String) async throws -> Object
    func getDocsList(with userId: String) async throws -> [Object]
    func deleteDocs(with projectId: Int, and userId: String) async throws
}

extension ProjectDocsManage {
    
    func fetchSingleDocsSnapshot(userId: String, projectId: Int, type: CollectionType) async throws -> DocumentSnapshot {
        let query = getFirestoreInstance()
            .collection(type.rawValue)
            .document(userId)
            .collection(type.rawValue)
            .document(String(projectId))
        return try await query.getDocument()
    }
    
    func fetchSingleDocsReference(_ userId: String, _ projectId: Int, _ type: CollectionType) async throws -> DocumentReference {
        return try await fetchSingleDocsSnapshot(userId: userId, projectId: projectId, type: type).reference
    }
    
    func fetchFullDocs(with userId: String) async throws -> [QueryDocumentSnapshot] {
        let instance = getFirestoreInstance()
        let collectionRef = instance
            .collection(CollectionType.project.rawValue)
            .document(userId)
            .collection(CollectionType.project.rawValue)
        
        async let ongoingSnapshot = collectionRef
            .whereField("user_id", isEqualTo: userId)
            .whereField("status", isEqualTo: ProjectStatus.ongoing.rawValue)
            .getDocuments()
        async let completableSnapshot = collectionRef
            .whereField("user_id", isEqualTo: userId)
            .whereField("status", isEqualTo: ProjectStatus.completable.rawValue)
            .getDocuments()
        
        let (ongoingResults, completableResults) = try await (ongoingSnapshot, completableSnapshot)
        return ongoingResults.documents + completableResults.documents
    }
}
