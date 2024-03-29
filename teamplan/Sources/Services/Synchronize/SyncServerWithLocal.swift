//
//  SyncServerWithLocal.swift
//  teamplan
//
//  Created by 크로스벨 on 1/10/24.
//  Copyright © 2024 team1os. All rights reserved.
//

import Foundation

final class SyncServerWithLocal {
    
    // for service
    private let util = Utilities()
    private let controller = CoredataController()
    
    private let userCD: UserServicesCoredata
    private let statCD: StatisticsServicesCoredata
    private let challengeCD: ChallengeServicesCoredata
    private let accessLogCD: AccessLogServicesCoredata
    
    private let userFS = UserServicesFirestore()
    private let statFS = StatisticsServicesFirestore()
    private let challengeFS = ChallengeServicesFirestore()
    private let accessLogFS = AccessLogServicesFirestore()
    
    private var userId: String
    private var previousSyncedAt: Date
    private var rollbackStack: [() throws -> Void ] = []
    
    init(with userId: String) {
        self.userId = userId
        self.previousSyncedAt = Date()
        
        self.userCD = UserServicesCoredata(coredataController: self.controller)
        self.statCD = StatisticsServicesCoredata(coredataController: self.controller)
        self.challengeCD = ChallengeServicesCoredata(coredataController: self.controller)
        self.accessLogCD = AccessLogServicesCoredata(coredataController: self.controller)
    }
    
    func syncExecutor(with userId: String, and syncDate: Date) async throws {
        self.userId = userId
        do {
            // User
            let user = try getUserFromLocal()
            rollbackStack.append(rollbackUserSyncedAt)
            try await updateServerUser(with: user)
            try applyUserSyncedAt(with: syncDate)
            
            // Statistics
            let stat = try getStatFromLocal()
            rollbackStack.append(rollbackStatSyncedAt)
            try await updateServerStatistics(with: stat)
            try applyStatSyncedAt(with: syncDate)
            
            // Challenge
            let challengeList = try getChallengeFromLocal()
            try await updateServerChallenge(with: challengeList)
            
            // AccessLog
            let accessLog = try getAccessLogFromLocal(with: syncDate)
            try await updateServerAccesslog(with: accessLog, and: user.accessLogHead)
            
            // Project Log (WIP)
        } catch {
            try rollbackAll()
            throw error
        }
    }
    private func rollbackAll() throws {
        for rollback in rollbackStack.reversed() {
            try rollback()
        }
        rollbackStack.removeAll()
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
        return try accessLogCD.getTargetObjects(with: userId, and: syncedAt)
    }
    
    // Challenge
    private func getChallengeFromLocal() throws -> [ChallengeObject] {
        return try challengeCD.getObjects(with: userId)
    }
    // Project Log (WIP)
}


// MARK: - Apply Server
extension SyncServerWithLocal{
    
    // User
    private func updateServerUser(with object: UserObject) async throws {
        try await userFS.updateDocs(with: object)
    }
    
    // Statistics
    private func updateServerStatistics(with object: StatisticsObject) async throws {
        try await statFS.updateDocs(with: object)
    }
    
    // Challenge
    private func updateServerChallenge(with objects: [ChallengeObject]) async throws {
        try await challengeFS.updateDocs(with: objects, and: userId)
    }
    
    // Access Log
    private func updateServerAccesslog(with log: [AccessLog], and logHead: Int) async throws {
        try await accessLogFS.setDocs(with: userId, and: logHead, and: log)
    }
    // Project Log (WIP)
}


// MARK: - Update Local SyncedAt
extension SyncServerWithLocal{
    
    // User
    private func applyUserSyncedAt(with syncDate: Date) throws {
        let updated = UserUpdateDTO(userId: userId, newSyncedAt: syncDate)
        try userCD.updateObject(with: updated)
    }
    private func rollbackStatSyncedAt() throws {
        let updated = UserUpdateDTO(userId: userId, newSyncedAt: previousSyncedAt)
        try userCD.updateObject(with: updated)
    }
    
    // Statistics
    private func applyStatSyncedAt(with syncDate: Date) throws {
        let updated = StatUpdateDTO(userId: userId, newSyncedAt: syncDate)
        try statCD.updateObject(with: updated)
    }
    private func rollbackUserSyncedAt() throws {
        let updated = StatUpdateDTO(userId: userId, newSyncedAt: previousSyncedAt)
        try statCD.updateObject(with: updated)
    }
    // Project Log (WIP)
}
