//
//  DocsManager.swift
//  투두팡
//
//  Created by Crossbell on 8/28/24.
//  Copyright © 2024 team1os. All rights reserved.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

final class DocsManager {
    
    static let shared = DocsManager()
    
    private let instance = Firestore.firestore()
    private var cachedDocs: [String: DocumentSnapshot] = [:]
    
    private init() {}

    // MARK: - Fetch Collection
    
    func fetchPrimaryCollection(for type: PrimaryCollection) -> CollectionReference {
        return instance.collection(type.rawValue)
    }
    
    func fetchSecondaryCollection(with userId: String, primary: PrimaryCollection, secondary: SecondaryCollection) -> CollectionReference {
        switch primary {
        case .stat, .coreValue, .challenge:
            return fetchPrimaryCollection(for: primary)
        case .user, .project:
            return instance
                .collection(primary.rawValue)
                .document(userId)
                .collection(secondary.rawValue)
        }
    }
    
    // MARK: - Fetch Docs
    
    private func fetchDocument(from request: DocumentReference) async -> DocumentSnapshot? {
        do {
            return try await request.getDocument()
        } catch {
            print("[DocsManager] Failed to get docs from collection: \(error.localizedDescription)")
            return nil
        }
    }
    
    func fetchPrimaryDocs(with userId: String, primary: PrimaryCollection) async -> DocumentSnapshot? {
        let request = fetchPrimaryCollection(for: primary).document(userId)
        return await fetchDocument(from: request)
    }
    
    func fetchSecondaryDocs(with userId: String, secondaryId: String, primary: PrimaryCollection, secondary: SecondaryCollection) async -> DocumentSnapshot? {
        let request = fetchSecondaryCollection(with: userId, primary: primary, secondary: secondary).document(secondaryId)
        return await fetchDocument(from: request)
    }
}
