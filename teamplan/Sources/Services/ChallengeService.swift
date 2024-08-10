//
//  ChallengeService.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/10/10.
//  Copyright © 2023 team1os. All rights reserved.
//

import CoreData
import Foundation

final class ChallengeService {
    
    // shared
    var rewardDTO: ChallengeRewardDTO
    @Published var myChallenges: [MyChallengeDTO] = []
    @Published var challengesDTO: [ChallengeDTO] = []
    
    // private
    private let statCD = StatisticsServicesCoredata()
    private let challengeCD = ChallengeServicesCoredata()
    private let localStorageManager: LocalStorageManager
    
    private var userId: String
    private var statDTO: StatDTO
    private var challengeDTOIndex: Int
    private var challengeData: ChallengeObject
    private var challengeList: [Int : ChallengeObject] = [:]
    private var isFianlChallenge: Bool = false
    
    init(with userId: String) {
        self.userId = userId        
        self.statDTO = StatDTO()
        self.rewardDTO = ChallengeRewardDTO()
        self.challengeDTOIndex = 0
        self.challengeData = ChallengeObject()
        self.localStorageManager = LocalStorageManager.shared
    }
}

// MARK: - Prepare Data

extension ChallengeService {

    // Executor
    func prepareExecutor() -> Bool {
        let context = localStorageManager.context
        var fetchResults = [Bool]()
        var prepareResults = [Bool]()
        
        context.performAndWait {
            fetchResults = [
                fetchStatObject(with: context),
                fetchChallengeObject(with: context)
            ]
        }
        
        if fetchResults.allSatisfy({ $0 }) {
            prepareResults = [
                prepareMyChallengeDTO(),
                prepareChallengeDTO()
            ]
        } else {
            print("[ChallengeService] Failed to fetch data")
            return false
        }
        
        let isSuccess = prepareResults.allSatisfy { $0 }
        print("[ChallengeService] \(isSuccess ? "Successfully" : "Failed to") prepare service")
        return isSuccess
    }
    
    // fetch: Statistics
    private func fetchStatObject(with context: NSManagedObjectContext) -> Bool {
        do {
            if try statCD.getObject(context: context, userId: userId) {
                self.statDTO = StatDTO(with: statCD.object)
                return true
            } else {
                print("[ChallengeService] Error detected while converting StatEntity to object")
                return false
            }
        } catch {
            print("[ChallengeService] Error detected while converting StatEntity: \(error.localizedDescription)")
            return false
        }
    }
    
    // fetch: Total Challenges
    private func fetchChallengeObject(with context: NSManagedObjectContext) -> Bool {
        do {
            if try challengeCD.getTotalObject(context: context, userId: userId) {
                for challenge in challengeCD.objects {
                    self.challengeList[challenge.challengeId] = challenge
                }
                return true
            } else {
                print("[ChallengeService] Error detected while converting ChallengeEntity to object")
                return false
            }
        } catch {
            print("[ChallengeService] Error detected while fetching entities: \(error.localizedDescription)")
            return false
        }
    }
    
    // prepare: MyChallenge
    private func prepareMyChallengeDTO() -> Bool {
        
        if statDTO.myChallenges.isEmpty {
            self.myChallenges = []
            return true
        }
        print("[ChallengeService] statData myChallenge: \(statDTO.myChallenges)")
        
        var challengeList = [MyChallengeDTO]()
        for index in statDTO.myChallenges {
            guard let challenge = self.challengeList[index] else {
                print("[ChallengeService] Error detected while search myChallenge data")
                return false
            }
            challengeList.append(MyChallengeDTO(with: challenge))
        
        }
        print("[ChallengeService] challengeList: \(challengeList)")
        self.myChallenges = challengeList.sorted{ $0.selectedAt < $1.selectedAt }
        return true
    }
    
    // prepare: ChallengeDTOs
    private func prepareChallengeDTO() -> Bool {
        
        for challenge in challengeList.values {
            if challenge.step == 1 {
                self.challengesDTO.append(mapFirstStepChallenge(with: challenge))
            } else {
                guard let previous = self.challengeList[challenge.challengeId - 1] else {
                    print("[ChallengeService] Failed to search previous challengeData")
                    return false
                }
                self.challengesDTO.append(mapOtherStepChallenges(with: challenge, and: previous))
            }
        }
        return true
    }
    
    private func mapFirstStepChallenge(with object: ChallengeObject) -> ChallengeDTO {
        return ChallengeDTO(
                challengeId: object.challengeId,
                title: object.title,
                desc: object.desc,
                goal: object.goal,
                type: object.type,
                reward: object.reward,
                step: object.step,
                isFinished: object.status,
                isSelected: object.selectStatus,
                isUnlock: object.lock,
                finishedAt: object.status ? object.finishedAt : nil
            )
    }
    
    private func mapOtherStepChallenges(with object: ChallengeObject, and prevObject: ChallengeObject) -> ChallengeDTO {
        return ChallengeDTO(
            challengeId: object.challengeId,
            title: object.title,
            desc: object.desc,
            goal: object.goal,
            type: object.type,
            reward: object.reward,
            step: object.step,
            isFinished: object.status,
            isSelected: object.selectStatus,
            isUnlock: object.lock,
            finishedAt: object.status ? object.finishedAt : nil,
            prevId: prevObject.challengeId,
            prevTitle: prevObject.title,
            prevDesc: prevObject.desc,
            prevGoal: prevObject.goal
        )
    }
}

// MARK: - Set myChallenge

extension ChallengeService {
    
    /// 특정 도전과제를 '나의 도전과제'로 등록합니다.
    /// - Parameter challengeId: '나의 도전과제'에 등록할 도전과제의 ID입니다.
    /// - Throws: 중복 도전과제, 최대 도전과제 수 초과 등으로 인한 오류를 던집니다.
    /// - 이 함수는 중복 검사를 수행하고, 도전과제를 'myChallenges'에 추가하며, 해당 도전과제의 상태를 업데이트합니다.
    /// - 또한 관련 통계 정보를 갱신하고, 모든 변경 사항을 로그로 출력합니다.
    func setMyChallenges(with challengeId: Int) -> Bool {
    
        // inspection
        if !canAppendMyChallenge(with: challengeId) {
            print("[ChallengeService] Can't regist anymore myChallenges")
            return false
        }
        
        // extract data
        if !getChallengeDataFromList(with: challengeId) || !getChallengeIndexFromDTOs(with: challengeId) {
            print("[ChallengeService] Unknown ChallengeId Detected")
            return false
        }
        
        let updatedAt = Date()
        let context = localStorageManager.context
        
        return context.performAndWait {
            // update dto
            updateDTOAboutSet(with: challengeId)
            
           // update object
            let results = [
                updateStatObjectAboutSet(with: context),
                updateChallengeObjectAboutSet(with: context, and: challengeId, at: updatedAt)
            ]
            
            // apply storage
            if results.allSatisfy({ $0 }) {
                if localStorageManager.saveContext() {
                    print("[ChallengeService] Successfully set new mychallenge at context")
                    return true
                } else {
                    print("[ChallengeService] Failed to set new mychallenge at context")
                    return false
                }
            } else {
                print("[ChallengeService] Failed to update objects")
                return false
            }
        }
    }
    
    private func canAppendMyChallenge(with challengeId: Int) -> Bool {
        return myChallenges.count < 3 &&
        statDTO.myChallenges.count < 3 &&
        !myChallenges.contains(where: { $0.challengeID == challengeId })
    }
    
    private func updateDTOAboutSet(with challengeId: Int) {
            
        self.statDTO.myChallenges.append(challengeId)
        self.myChallenges.append(MyChallengeDTO(with: self.challengeData))
        self.challengesDTO[self.challengeDTOIndex].isSelected = true
    }
    
    private func updateChallengeObjectAboutSet(with context: NSManagedObjectContext, and challengeId: Int, at updatedAt: Date) -> Bool {
        
        var updated = ChallengeUpdateDTO(challengeId: challengeId, userId: userId)
        let userProgress = getUserProgress(with: self.challengeData.type)
        
        updated.newProgress = userProgress
        updated.newSelectStatus = true
        updated.newSelectedAt = updatedAt
        
        do {
            return try challengeCD.updateObject(context: context, dto: updated)
        } catch {
            print("[ChallengeService] Error detected while search entity: \(error.localizedDescription)")
            return false
        }
    }
    
    private func updateStatObjectAboutSet(with context: NSManagedObjectContext) -> Bool {
        do {
            let newMyChallenges = self.statDTO.myChallenges
            let updated = StatUpdateDTO(userId: userId, newMyChallenges: newMyChallenges)
            return try statCD.updateObject(context: context, dto: updated)
        } catch {
            print("[ChallengeService] Error detected while search entity: \(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - Disable myChallenge
    
    /// '나의 도전과제'로 등록된 특정 도전과제를 해제합니다.
    /// - Parameter challengeId: '나의 도전과제'에서 해제할 도전과제의 ID입니다.
    /// - Throws: 도전과제 해제 및 상태 업데이트에서 발생한 오류들을 던집니다.
    /// - 이 함수는 도전과제를 'myChallenges'에 제거하며, 해당 도전과제의 상태를 업데이트합니다.
    /// - 또한 관련 통계 정보를 갱신하고, 모든 변경 사항을 로그로 출력합니다.
    func disableMyChallenge(with challengeId: Int) -> Bool {
        
        // extract data
        if !getChallengeDataFromList(with: challengeId) || !getChallengeIndexFromDTOs(with: challengeId) {
            print("[ChallengeService] Unknown ChallengeId Detected")
            return false
        }
        
        let updatedAt = Date()
        let context = localStorageManager.context
 
        return context.performAndWait {
            // update dto
            updateDTOAboutDisable(with: challengeId)
            
           // update object
            let results = [
                updateStatObjectAboutDisable(with: context),
                updateChallengeObjectAboutDisable(with: context, and: challengeId, at: updatedAt)
            ]
            
            // apply storage
            if results.allSatisfy({ $0 }) {
                if localStorageManager.saveContext() {
                    print("[ChallengeService] Successfully saved context")
                    return true
                } else {
                    print("[ChallengeService] Failed to save context")
                    return false
                }
            } else {
                print("[ChallengeService] Failed to update objects")
                return false
            }
        }
    }
    
    private func updateDTOAboutDisable(with challengeId: Int) {
        
        self.statDTO.myChallenges.removeAll { $0 == challengeId }
        self.myChallenges.removeAll{ $0.challengeID == challengeId }
        self.challengesDTO[self.challengeDTOIndex].isSelected = false
    }
    
    private func updateChallengeObjectAboutDisable(with context: NSManagedObjectContext, and challengeId: Int, at updatedAt: Date) -> Bool {
        
        var updated = ChallengeUpdateDTO(challengeId: challengeId, userId: userId)
        
        updated.newSelectStatus = false
        updated.newUnSelectedAt = updatedAt
        
        do {
            return try challengeCD.updateObject(context: context, dto: updated)
        } catch {
            print("[ChallengeService] Error detected while search entity: \(error.localizedDescription)")
            return false
        }
    }
    
    private func updateStatObjectAboutDisable(with context: NSManagedObjectContext) -> Bool {
        do {
            let newMyChallenges = self.statDTO.myChallenges
            let updated = StatUpdateDTO(userId: userId, newMyChallenges: newMyChallenges)
            
            return try statCD.updateObject(context: context, dto: updated)
        } catch {
            print("[ChallengeService] Error detected while search entity: \(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - Reward myChallenge

    /// 완료한 도전과제에 대한 보상을 처리합니다.
    /// - Parameter challengeId: 보상을 받을 도전과제의 ID입니다.
    /// - Returns: 챌린지 완료에 따른 보상 정보를 `ChallengeRewardDTO`형태로 반환합니다.
    /// - Throws: 보상 처리 과정에서 발생한 오류를 던집니다.
    /// - 이 함수는 도전과제 보상을 지급하며, 해당 도전과제와 다음 도전과제의 상태를 업데이트합니다.
    /// - 또한 관련 통계 정보를 갱신하고, '나의 도전과제'에서 해당 도전과제를 해제합니다.
    /// - 모든 변경 사항 및 보상정보를 로그로 출력합니다.
    func rewardMyChallenge(with challengeId: Int) -> Bool {
        
        guard getChallengeDataFromList(with: challengeId),
              getChallengeIndexFromDTOs(with: challengeId),
              getNextChallengeData(with: self.challengeData) else {
            print("[ChallengeService] Unknown or invalid ChallengeId Detected")
            return false
        }

        let updatedAt = Date()
        let currentChallengeData = self.challengeData
        let currentChallengeIndex = self.challengeDTOIndex
        let context = localStorageManager.context

        return context.performAndWait {
            // Update current challenge
            updateCurrentDTOAboutReward(with: challengeId, and: currentChallengeIndex, at: updatedAt)
            let updateCurrentResults = [
                updateCurrentChallengeAboutReward(with: context, with: challengeId, at: updatedAt),
                updateCurrentStatAboutReward(with: context)
            ]

            guard updateCurrentResults.allSatisfy({ $0 }) else {
                print("[ChallengeService] Failed to update current reward objects")
                return false
            }

            self.rewardDTO = ChallengeRewardDTO(with: currentChallengeData)

            // Update next challenge if not the final challenge
            if !self.isFianlChallenge {
                let nextChallenge = self.challengeData
                let nextChallengeId = nextChallenge.challengeId
                guard getChallengeIndexFromDTOs(with: nextChallengeId) else {
                    print("[ChallengeService] Unknown Next ChallengeId Detected")
                    return false
                }
                let nextChallengeIndex = self.challengeDTOIndex

                updateNextDTOAboutReward(with: currentChallengeIndex, and: nextChallengeIndex)
                let updateNextResults = [
                    updateNextChallengeAboutReward(with: context, with: nextChallengeId),
                    updateNextStatAboutReward(with: context)
                ]

                guard updateNextResults.allSatisfy({ $0 }) else {
                    print("[ChallengeService] Failed to update next reward objects")
                    return false
                }
                self.rewardDTO = ChallengeRewardDTO(with: currentChallengeData, and: nextChallenge)
            }

            guard localStorageManager.saveContext() else {
                print("[ChallengeService] Failed to apply localStorage")
                return false
            }
            return true
        }
    }
    
    // update current: dto
    private func updateCurrentDTOAboutReward(with challengeId: Int, and index: Int, at updatedAt: Date) {
        
        self.statDTO.drop += self.challengesDTO[index].reward
        self.statDTO.myChallenges.removeAll{ $0 == challengeId }
        
        self.myChallenges.removeAll{ $0.challengeID == challengeId }
        
        self.challengesDTO[index].isSelected = false
        self.challengesDTO[index].isFinished = true
        self.challengesDTO[index].finishedAt = updatedAt
    }
    
    // update current: object
    private func updateCurrentChallengeAboutReward(with context: NSManagedObjectContext, with challengeId: Int,at updatedAt: Date) -> Bool {
        
        var updated = ChallengeUpdateDTO(challengeId: challengeId, userId: userId)
        
        updated.newStatus = true
        updated.newSelectStatus = false
        updated.newFinishedAt  = updatedAt
        
        do {
            return try challengeCD.updateObject(context: context, dto: updated)
        } catch {
            print("[ChallengeService] Error detected while search entity: \(error.localizedDescription)")
            return false
        }
    }
    
    private func updateCurrentStatAboutReward(with context: NSManagedObjectContext) -> Bool {
        
        var updated = StatUpdateDTO(userId: userId)
        
        updated.newDrop = statDTO.drop
        updated.newMyChallenges = statDTO.myChallenges
        
        do {
            return try statCD.updateObject(context: context, dto: updated)
        } catch {
            print("[ChallengeService] Error detected while search entity: \(error.localizedDescription)")
            return false
        }
    }
    
    // update next: dto
    private func updateNextDTOAboutReward(with currentIndex: Int, and nextIndex: Int) {
        
        let currentType = self.challengesDTO[currentIndex].type.rawValue
        
        self.statDTO.challengeStepStatus[currentType]! += 1
        self.challengesDTO[nextIndex].islock = true
    }
    
    // update next: object
    private func updateNextChallengeAboutReward(with context: NSManagedObjectContext, with challengeId: Int) -> Bool {
        
        var updated = ChallengeUpdateDTO(challengeId: challengeId, userId: userId)
        
        updated.newLock = false
        
        do {
            return try challengeCD.updateObject(context: context, dto: updated)
        } catch {
            print("[ChallengeService] Error detected while search entity: \(error.localizedDescription)")
            return false
        }
    }
    
    private func updateNextStatAboutReward(with context: NSManagedObjectContext) -> Bool {
        
        var updated = StatUpdateDTO(userId: userId)
        
        updated.newChallengeStepStatus = statDTO.challengeStepStatus
        
        do {
            return try statCD.updateObject(context: context, dto: updated)
        } catch {
            print("[ChallengeService] Error detected while search entity: \(error.localizedDescription)")
            return false
        }
    }
}

// MARK: Util

extension ChallengeService {
    
    private func getChallengeDataFromList(with challengeId: Int) -> Bool {
        guard let data = challengeList[challengeId] else {
            print("[ChallengeService] Failed to search ChallengeData at List")
            return false
        }
        self.challengeData = data
        return true
    }
    
    private func getChallengeIndexFromDTOs(with challengeId: Int) -> Bool {
        guard let index = challengesDTO.firstIndex(where: { $0.challengeId == challengeId}) else {
            print("[ChallengeService] Failed to search ChallengeIndex at List")
            return false
        }
        self.challengeDTOIndex = index
        return true
    }
    
    private func getNextChallengeData(with currentChallenge: ChallengeObject) -> Bool {
        // Final Challenge
        if currentChallenge.step == getChallengeStepLimit(with: currentChallenge.type) {
            print("[ChallengeService] Final challenge step complete")
            self.isFianlChallenge = true
            return true
        
        // onGoing Challenge
        } else if let nextChallenge = challengeList.values.first(where: {
            ( $0.type == currentChallenge.type ) && ( $0.step == currentChallenge.step + 1 )
        }) {
            self.challengeData = nextChallenge
            return true
            
        // unknown challenge
        } else {
            print("[ChallengeService] Failed to search NextChallenge")
            self.challengeData = ChallengeObject()
            return false
        }
    }
    
    private func getUserProgress(with type: ChallengeType) -> Int {
        switch type {
        case .onboarding:
            return 1
        case .serviceTerm:
            return statDTO.term
        case .totalTodo:
            return statDTO.totalRegistedTodos
        case .projectAlert:
            return statDTO.totalAlertedProjects
        case .projectFinish:
            return statDTO.totalFinishedProjects
        case .waterDrop:
            return statDTO.drop
        case .unknownType:
            return 0
        }
    }
    
    private func getChallengeStepLimit(with type: ChallengeType) -> Int {
        switch type {
        case .onboarding:
            return 0
        case .serviceTerm:
            return 7
        case .totalTodo:
            return 7
        case .projectAlert:
            return 5
        case .projectFinish:
            return 6
        case .waterDrop:
            return 11
        case .unknownType:
            return 0
        }
    }
}

// MARK: DTO

public struct ChallengeDTO: Equatable, Sendable {

    var challengeId: Int
    let title: String
    let desc: String
    let goal: Int
    let type: ChallengeType
    let reward: Int
    let step: Int
    
    var isFinished: Bool
    var isSelected: Bool
    var islock: Bool
    var finishedAt: Date?
    
    let prevId: Int?
    let prevTitle: String?
    let prevDesc: String?
    let prevGoal: Int?
    
    init(challengeId: Int,
         title: String,
         desc: String,
         goal: Int,
         type: ChallengeType,
         reward: Int,
         step: Int,
         isFinished: Bool,
         isSelected: Bool,
         isUnlock: Bool,
         finishedAt: Date? = nil,
         prevId: Int? = nil,
         prevTitle: String? = nil,
         prevDesc: String? = nil,
         prevGoal: Int? = nil)
    {
        self.challengeId = challengeId
        self.title = title
        self.desc = desc
        self.goal = goal
        self.type = type
        self.reward = reward
        self.step = step
        self.isFinished = isFinished
        self.isSelected = isSelected
        self.islock = isUnlock
        self.finishedAt = finishedAt
        self.prevId = prevId
        self.prevTitle = prevTitle
        self.prevDesc = prevDesc
        self.prevGoal = prevGoal
    }
}

struct MyChallengeDTO: Hashable, Identifiable {

    let id = UUID().uuidString
    var challengeID: Int
    let type: ChallengeType
    let title: String
    let desc: String
    let goal: Int
    let progress: Int
    let selectedAt: Date
    
    init() {
        self.challengeID = 0
        self.type = .unknownType
        self.title = "unknown"
        self.desc = "unknown"
        self.goal = 0
        self.progress = 0
        self.selectedAt = Date()
    }
    
    init(with object: ChallengeObject){
        self.challengeID = object.challengeId
        self.type = object.type
        self.title = object.title
        self.desc = object.desc
        self.goal = object.goal
        self.progress = object.progress
        self.selectedAt = object.selectedAt
    }
}

struct ChallengeRewardDTO {

    let title: String
    let desc: String
    let type: ChallengeType
    let reward: Int
    let setMyChallengeAt: Date
    let completeAt: Date
    
    init() {
        self.title = "unknown"
        self.desc = "unknown"
        self.type = .unknownType
        self.reward = 0
        self.setMyChallengeAt = Date()
        self.completeAt = Date()
    }
    
    init(with object: ChallengeObject) {
        self.title = "마지막 도전과제!"
        self.desc = "축하합니다! 관련된 모든 도전과제를 해결하였습니다!"
        self.type = object.type
        self.reward = object.reward
        self.setMyChallengeAt = object.selectedAt
        self.completeAt = object.finishedAt
    }
    
    init(with object: ChallengeObject, and nextObject: ChallengeObject) {
        self.title = nextObject.title
        self.desc = nextObject.desc
        self.type = nextObject.type
        self.reward = object.reward
        self.setMyChallengeAt = object.selectedAt
        self.completeAt = object.finishedAt
    }
}
