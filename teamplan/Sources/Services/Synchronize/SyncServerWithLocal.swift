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
    
    private let userCD: UserServicesCoredata
    private let statCD: StatisticsServicesCoredata
    private let challengeCD: ChallengeServicesCoredata
    private let accessLogCD: AccessLogServicesCoredata
    private let projectCD: ProjectServicesCoredata
    
    private let userFS = UserServicesFirestore()
    private let statFS = StatisticsServicesFirestore()
    private let challengeFS = ChallengeServicesFirestore()
    private let accessLogFS = AccessLogServicesFirestore()
    private let projectFS = ProjectServicesFirestore()
    
    private let instance = Firestore.firestore()
    private var userId: String
    private var logHead: Int
    private var previousSyncedAt: Date
    
    init(with userId: String, controller: CoredataController = CoredataController()) {
        self.userId = userId
        self.logHead = 0
        self.previousSyncedAt = Date()
        
        self.userCD = UserServicesCoredata(coredataController: controller)
        self.statCD = StatisticsServicesCoredata(coredataController: controller)
        self.challengeCD = ChallengeServicesCoredata(coredataController: controller)
        self.accessLogCD = AccessLogServicesCoredata(coredataController: controller)
        self.projectCD = ProjectServicesCoredata(coredataController: controller)
    }
    
    func syncExecutor(with userId: String, and syncDate: Date) async throws {
        self.userId = userId
        let batch = self.instance.batch()
        
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
        try deleteLegacyAccessLog()
    }
}


// MARK: - Fetch Local Data
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
    private func getAccessLogFromLocal(with syncedAt: Date) throws -> [AccessLog] {
        return try accessLogCD.getPartialObjects(with: userId, and: syncedAt)
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
            
            // New Registed At Firestore
            if project.registedAt == project.syncedAt {
                batch.setData(projectData, forDocument: projectRef)
            } else {
                batch.updateData(projectData, forDocument: projectRef)
            }
            
            // delete local project excpet ongoing or completable project
            if shouldDeleteProjectAtLocal(with: project.status) {
                try projectCD.deleteObject(with: userId, and: project.projectId)
            }
        }
    }
    private func shouldDeleteProjectAtLocal(with status: ProjectStatus) -> Bool {
        return status != .ongoing || status != .completable
    }
    
    // Access Log
    private func updateServerAccesslog(with batch: WriteBatch, at syncedAt: Date) async throws {
        let accessLog = try getAccessLogFromLocal(with: syncedAt)
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
    
    // log
    private func deleteLegacyAccessLog() throws {
        try accessLogCD.deleteObject(with: userId)
    }
}
