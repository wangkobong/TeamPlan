//
//  SyncServerWithLocal.swift
//  teamplan
//
//  Created by 크로스벨 on 1/10/24.
//  Copyright © 2024 team1os. All rights reserved.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

final class SyncServerWithLocal {
    
    private let userCD = UserServicesCoredata()
    private let statCD = StatisticsServicesCoredata()
    private let challengeCD = ChallengeServicesCoredata()
    private let accessLogCD = AccessLogServicesCoredata()
    private let projectCD = ProjectServicesCoredata()
    
    private let userFS = UserServicesFirestore()
    private let statFS = StatisticsServicesFirestore()
    private let challengeFS = ChallengeServicesFirestore()
    private let accessLogFS = AccessLogServicesFirestore()
    private let projectFS = ProjectServicesFirestore()
    
    private var userId: String
    private var logHead: Int
    private var previousSyncedAt: Date
    private var updatedProject = Set<Int>()
    
    init(with userId: String) {
        self.userId = userId
        self.logHead = 0
        self.previousSyncedAt = Date()
    }
    
    // MARK: - Sync Executor
    func syncExecutor(with userId: String, and syncDate: Date) async throws {
        
        self.userId = userId
        let batch = Firestore.firestore().batch()
        // User
        try await updateServerUser(with: batch)

        // Statistics
        try await updateServerStatistics(with: batch)
        
        // Challenge
        try await updateServerChallenge(with: batch)
        
        // Project
        try await updateServerProject(with: batch)
        
        // AccessLog
        try await updateServerAccesslog(with: batch, at: syncDate)
        
        try await batch.commit()
        
        try updateSyncDate(with: syncDate)
    }
    
    private func updateSyncDate(with syncDate: Date) throws {
        try applyUserSyncedAt(with: syncDate)
        try applyStatSyncedAt(with: syncDate)
        try applyProjectSyncedAt(with: syncDate)
        try deleteLegacyAccessLog()
    }
    
    // MARK: - Delete Executor
    func deleteExecutor(with userId: String) async throws {
        self.userId = userId
        let batch = Firestore.firestore().batch()
        
        // User
        try deleteUserAtLocal()
        try await deleteUserAtServer(with: batch)
        
        // Statistics
        try deleteStatAtLocal()
        try await deleteStatAtServer(with: batch)
        
        // Challenge
        try deleteChallengeAtLocal()
        try await deleteChallengeAtServer(with: batch)
        
        // Project
        try deleteProjectAtLocal()
        try await deleteProjectAtServer(with: batch)
        
        // AccessLog
        try deleteAccessLogAtLocal()
        try await deleteAccessLogAtServer(with: batch)
        
        try await batch.commit()
    }
}


// MARK: - Fetch Data from local
extension SyncServerWithLocal{
    
    // User
    private func getUserFromLocal() throws -> UserObject {
        let user = try userCD.getObject(with: userId)
        self.previousSyncedAt = user.syncedAt
        return user
    }
    
    // Statistics
    private func getStatFromLocal() throws -> StatisticsObject {
        return try statCD.getObject(with: userId)
    }
    
    // Access Log
    private func getAccessLogFromLocal() throws -> [AccessLog] {
        return try accessLogCD.getFullObjects(with: userId)
    }
    
    // Challenge
    private func getChallengeFromLocal() throws -> [ChallengeObject] {
        return try challengeCD.getObjects(with: userId)
    }
    
    // Project
    private func getProjectFromLocal() throws -> [ProjectObject] {
        return try projectCD.getObjects(with: userId)
    }
}


// MARK: - Apply Server
extension SyncServerWithLocal{
    
    // User
    private func updateServerUser(with batch: WriteBatch) async throws {
        let user = try getUserFromLocal()
        let userRef = try await userFS.fetchDocsReference(with: userId, and: .user)
        let userData = userFS.convertToData(with: user)
        batch.updateData(userData, forDocument: userRef)
        self.logHead = user.accessLogHead
    }
    
    // Statistics
    private func updateServerStatistics(with batch: WriteBatch) async throws {
        let stat = try getStatFromLocal()
        let statRef = try await statFS.fetchDocsReference(with: userId, and: .stat)
        let statData = try statFS.convertToData(with: stat)
        batch.updateData(statData, forDocument: statRef)
    }
    
    // Challenge
    private func updateServerChallenge(with batch: WriteBatch) async throws {
        let challengeList = try getChallengeFromLocal()
        for challenge in challengeList {
            let challengeRef = try await challengeFS.fetchStatusDocsReference(with: userId, and: challenge.challengeId)
            let challengeData = challengeFS.convertObjectToStatus(with: challenge)
            batch.updateData(challengeData, forDocument: challengeRef)
        }
    }
    
    // Project(Status)
    private func updateServerProject(with batch: WriteBatch) async throws {
        let projectList = try getProjectFromLocal()
        for project in projectList {
            
            // prepare data & reference
            let projectRef = try await projectFS.fetchSingleDocsReference(userId, project.projectId, .project)
            let projectData = projectFS.convertToData(with: project)
            
            // set batch process
            if project.registedAt == project.syncedAt {
                batch.setData(projectData, forDocument: projectRef)
            } else {
                batch.updateData(projectData, forDocument: projectRef)
            }
            
            // add updated projectId
            self.updatedProject.insert(project.projectId)
        }
    }
    
    // Access Log
    private func updateServerAccesslog(with batch: WriteBatch, at syncedAt: Date) async throws {
        let accessLog = try getAccessLogFromLocal()
        for log in accessLog {
            let accessLogRef = accessLogFS.fetchCollectionReference(with: userId, and: self.logHead).document()
            let accessLogData = accessLogFS.convertToData(with: log)
            batch.setData(accessLogData, forDocument: accessLogRef)
        }
    }
}


// MARK: - Update SyncedAt
extension SyncServerWithLocal{
    
    // User
    private func applyUserSyncedAt(with syncDate: Date) throws {
        let updated = UserUpdateDTO(userId: userId, newSyncedAt: syncDate)
        try userCD.updateObject(with: updated)
    }
    
    // Statistics
    private func applyStatSyncedAt(with syncDate: Date) throws {
        let updated = StatUpdateDTO(userId: userId, newSyncedAt: syncDate)
        try statCD.updateObject(with: updated)
    }
    
    // Project
    private func applyProjectSyncedAt(with syncDate: Date) throws {
        for projectId in updatedProject {
            let updated = ProjectUpdateDTO(projectId: projectId, userId: userId, newSyncedAt: syncDate)
            try projectCD.updateObject(with: updated)
        }
    }
    
    // log
    private func deleteLegacyAccessLog() throws {
        try accessLogCD.deleteObject(with: userId)
    }
}


// MARK: - Delete Data at local
extension SyncServerWithLocal{
    
    // User
    private func deleteUserAtLocal() throws {
        try userCD.deleteObject(with: userId)
    }
    
    // Statistics
    private func deleteStatAtLocal() throws {
        try statCD.deleteObject(with: userId)
    }
    
    // Access Log
    private func deleteAccessLogAtLocal() throws {
        try accessLogCD.deleteObject(with: userId)
    }
    
    // Challenge
    private func deleteChallengeAtLocal() throws {
        try challengeCD.deleteObject(with: userId)
    }
    
    // project
    private func deleteProjectAtLocal() throws {
        try projectCD.deleteAllObject(with: userId)
    }
}

// MARK: - Delete Data from Server
extension SyncServerWithLocal{
    
    private func deleteUserAtServer(with batch: WriteBatch) async throws {
        let userRef = try await userFS.fetchDocsReference(with: userId, and: .user)
        batch.deleteDocument(userRef)
    }
    
    private func deleteStatAtServer(with batch: WriteBatch) async throws {
        let statRef = try await statFS.fetchDocsReference(with: userId, and: .stat)
        batch.deleteDocument(statRef)
    }
    
    private func deleteChallengeAtServer(with batch: WriteBatch) async throws {
        let challengeStatusRef = try await challengeFS.fetchStatusReference(with: userId)
        batch.deleteDocument(challengeStatusRef)
    }
    
    private func deleteProjectAtServer(with batch: WriteBatch) async throws {
        let projectRef = try await projectFS.fetchFullDocsReference(with: userId)
        batch.deleteDocument(projectRef)
    }
    
    private func deleteAccessLogAtServer(with batch: WriteBatch) async throws {
        let accessLogRef = try await accessLogFS.fetchFullDocsReference(with: userId)
        batch.deleteDocument(accessLogRef)
    }
}
