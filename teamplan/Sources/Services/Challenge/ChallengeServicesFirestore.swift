//
//  ChallengeServicesFirestore.swift
//  teamplan
//
//  Created by 주찬혁 on 11/27/23.
//  Copyright © 2023 team1os. All rights reserved.

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

final class ChallengeServicesFirestore: ChallengeDocsManage {
    typealias Object = ChallengeObject
    typealias infoDTO = ChallengeInfoDTO
    typealias statusDTO = ChallengeStatusDTO
    
    func setDocs(with objects: [Object], and userId: String) async throws {
        let batch = getFirestoreInstance().batch()
        let collectionRef = fetchCollection(with:.challengeStatus).document(userId).collection(CollectionType.challengeStatus.rawValue)
        for object in objects {
            let docsRef = collectionRef.document(String(object.challengeId))
            batch.setData(convertObjectToStatus(with: object), forDocument: docsRef)
        }
        try await batch.commit()
    }
    
    func getInfoDocsList() async throws -> [infoDTO] {
        let docs = try await fetchChallengeDocs(with: .challengeInfo)
        return try docs.map { try convertInfoToDTO(with: $0.data()) }
    }
    
    func getStatusDocsList(with userId: String) async throws -> [statusDTO] {
        let docsRef = try await fetchDocuments(with: userId, and: .challengeStatus)
        return try docsRef.map { try convertStatusToObject(with: $0.data()) }
    }
    
    func updateDocs(with objects: [Object], and userId: String) async throws {
        let batch = getFirestoreInstance().batch()
        let collectionRef = fetchCollection(with: .challengeStatus).document(userId).collection(CollectionType.challengeStatus.rawValue)
        
        for object in objects{
            let docsRef = collectionRef.document(String(object.challengeId))
            batch.updateData(convertObjectToStatus(with: object), forDocument: docsRef)
        }
        try await batch.commit()
    }
    
    func deleteDocs(with userId: String) async throws {
        let batch = getFirestoreInstance().batch()
        let docsRef = try await fetchDocuments(with: userId, and: .challengeStatus)
        
        for doc in docsRef {
            batch.deleteDocument(doc.reference)
        }
        try await batch.commit()
    }
}

// MARK: - Converter
struct ChallengeInfoDTO {
    let challengeId: Int
    let title: String
    let desc: String
    let goal: Int
    let type: ChallengeType
    let reward: Int
    let step: Int
    let version: Int
    
    init(challengeId: Int, 
         title: String,
         desc: String,
         goal: Int,
         type: ChallengeType,
         reward: Int,
         step: Int,
         version: Int
    ){
        self.challengeId = challengeId
        self.title = title
        self.desc = desc
        self.goal = goal
        self.type = type
        self.reward = reward
        self.step = step
        self.version = version
    }
}

struct ChallengeStatusDTO {
    let challengeId: Int
    let userId: String
    let status: Bool
    let lock: Bool
    let progress: Int
    let selectStatus: Bool
    let selectedAt: Date
    let unselectedAt: Date
    let finishedAt: Date
    
    init(challengeId: Int, 
         userId: String,
         status: Bool,
         lock: Bool,
         progress: Int,
         selectStatus: Bool,
         selectedAt: Date,
         unselectedAt: Date,
         finishedAt: Date
    ){
        self.challengeId = challengeId
        self.userId = userId
        self.status = status
        self.lock = lock
        self.progress = progress
        self.selectStatus = selectStatus
        self.selectedAt = selectedAt
        self.unselectedAt = unselectedAt
        self.finishedAt = finishedAt
    }
}

extension ChallengeServicesFirestore {
    private func convertObjectToStatus(with object: Object) -> [String:Any] {
        let stringSelectedAt = DateFormatter.standardFormatter.string(from: object.selectedAt)
        let stringUnselectedAt = DateFormatter.standardFormatter.string(from: object.unselectedAt)
        let finishedAt = DateFormatter.standardFormatter.string(from: object.finishedAt)
        
        return [
            "user_id": object.userId,
            "challenge_id": object.challengeId,
            "status": object.status,
            "lock": object.lock,
            "progress": object.progress,
            "select_status": object.selectStatus,
            "selected_at": stringSelectedAt,
            "unselected_at": stringUnselectedAt,
            "finished_at": finishedAt
        ]
    }
    
    // First Challenge Initialize Only
    private func convertInfoToDTO(with data: [String:Any]) throws -> infoDTO {
        guard let challengeId = data["chlg_id"] as? Int,
              let title = data["chlg_title"] as? String,
              let desc = data["chlg_desc"] as? String,
              let goal = data["chlg_goal"] as? Int,
              let rawType = data["chlg_type"] as? Int,
              let type = ChallengeType(rawValue: rawType),
              let reward = data["chlg_reward"] as? Int,
              let step = data["chlg_step"] as? Int
        else {
            throw FirestoreError.convertFailure(serviceName: .challenge)
        }
        return infoDTO (
            challengeId: challengeId,
            title: title,
            desc: desc,
            goal: goal,
            type: type,
            reward: reward,
            step: step,
            version: 1
        )
    }
    
    // Synchronize Challenge Only
    private func convertStatusToObject(with data: [String:Any]) throws -> statusDTO {
        guard let challengeId = data["challenge_id"] as? Int,
              let userId = data["user_id"] as? String,
              let status = data["status"] as? Bool,
              let lock = data["lock"] as? Bool,
              let progress = data["progress"] as? Int,
              let selectStatus = data["select_status"] as? Bool,
              let stringSelectedAt = data["selected_at"] as? String,
              let selectedAt = DateFormatter.standardFormatter.date(from: stringSelectedAt),
              let stringUnselectedAt = data["unselected_at"] as? String,
              let unselectedAt = DateFormatter.standardFormatter.date(from: stringUnselectedAt),
              let stringFinishedAt = data["finished_at"] as? String,
              let finishedAt = DateFormatter.standardFormatter.date(from: stringFinishedAt)
        else {
            throw FirestoreError.convertFailure(serviceName: .challenge)
        }
        return statusDTO (
            challengeId: challengeId,
            userId: userId,
            status: status,
            lock: lock,
            progress: progress,
            selectStatus: selectStatus,
            selectedAt: selectedAt,
            unselectedAt: unselectedAt,
            finishedAt: finishedAt
        )
    }
}

