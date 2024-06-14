//
//  ChallengeManager.swift
//  teamplan
//
//  Created by 크로스벨 on 6/13/24.
//  Copyright © 2024 team1os. All rights reserved.
//

import Foundation

final class ChallengeManager {
    
    private let notificationService: NotificationServicesCoredata
    private let challengeService: ChallengeServicesCoredata
    
    init() {
        self.notificationService = NotificationServicesCoredata()
        self.challengeService = ChallengeServicesCoredata()
    }
    
    func confirmMyChallenges(for statDTO: StatDTO) async -> Bool {
        let myChallenges = statDTO.myChallenges
        guard await checkMyChallengeList(myChallenges) else { return false }
        return await checkMyChallengeProgress(for: myChallenges, with: statDTO)
    }
    
    private func checkMyChallengeList(_ myChallengeList: [Int]) async -> Bool {
        if myChallengeList.isEmpty {
            print("[ChallengeManager] No challenges to check")
            return false
        } else {
            return true
        }
    }
    
    private func checkMyChallengeProgress(for myChallengeList: [Int], with statDTO: StatDTO) async -> Bool {
        for challengeId in myChallengeList {
            do {
                let challenge = try await fetchChallengeData(for: statDTO.userId, challengeId: challengeId)
                let progress = await getProgress(for: challenge.type, with: statDTO)
                if progress >= challenge.goal {
                    await createNotification(for: statDTO, challengeId: challengeId, title: challenge.title)
                }
            } catch {
                print("[ChallengeManager] Error processing challengeId \(challengeId): \(error)")
            }
        }
        return true
    }
    
    private func fetchChallengeData(for userId: String, challengeId: Int) async throws -> ChallengeObject {
        return try await challengeService.getObject(with: challengeId, and: userId)
    }
    
    private func getProgress(for type: ChallengeType, with statDTO: StatDTO) async -> Int {
        switch type {
        case .onboarding, .unknownType:
            return 0
        case .serviceTerm:
            return statDTO.term
        case .waterDrop:
            return statDTO.drop
        case .projectAlert:
            return statDTO.totalAlertedProjects
        case .projectFinish:
            return statDTO.totalFinishedProjects
        case .totalTodo:
            return statDTO.totalRegistedTodos
        }
    }
    
    private func createNotification(for statDTO: StatDTO, challengeId: Int, title: String) async {
        let notification = NotificationObject(
            userId: statDTO.userId,
            challengeId: challengeId,
            type: .challenge,
            title: title,
            desc: "Challenge completed: \(title)",
            date: Date(),
            isCheck: false
        )
        do {
            try await notificationService.setObject(with: notification)
            print("[ChallengeManager] Notification created for challengeId \(challengeId)")
        } catch {
            print("[ChallengeManager] Failed to save notification for challengeId \(challengeId): \(error)")
        }
    }
}
