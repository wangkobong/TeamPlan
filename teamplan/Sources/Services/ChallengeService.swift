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
    var myChallenges: [MyChallengeDTO] = []
    var challengesDTO: [ChallengeDTO] = []
    
    // private
    private let statCD: StatisticsServicesCoredata
    private let challengeCD: ChallengeServicesCoredata
    private let localStorageManager: LocalStorageManager
    
    private var userId: String
    private var statDTO: StatDTO
    private var challengeDTOIndex: Int
    private var challengeData: ChallengeObject
    private var challengeList: [Int : ChallengeObject] = [:]
    private var isFianlChallenge: Bool = false
    private var previousDate: Date
    
    init(with userId: String) {
        self.userId = userId        
        self.statDTO = StatDTO()
        self.rewardDTO = ChallengeRewardDTO()
        self.challengeDTOIndex = 0
        self.challengeData = ChallengeObject()
        self.previousDate = Date()
        
        self.statCD = StatisticsServicesCoredata()
        self.challengeCD = ChallengeServicesCoredata()
        self.localStorageManager = LocalStorageManager.shared
    }
}

extension ChallengeService {

    // Executor
    func prepareExecutor() async -> Bool {
        let context = localStorageManager.context
        var fetchResults = [Bool]()
        
        context.performAndWait {
            fetchResults = [
                fetchStatObject(with: context),
                fetchChallengeObject(with: context)
            ]
        }
        guard fetchResults.allSatisfy({ $0 }) else {
            print("[ChallengeSC] Failed to fetch data")
            return false
        }
        
        async let isMyChallengeReady = prepareMyChallengeDTO()
        async let isChallengeListReady = prepareChallengeDTO()
        let prepareResult = await [isMyChallengeReady, isChallengeListReady]
        
        guard prepareResult.allSatisfy({$0}) else {
            print("[ChallengeSC] Failed to preprocessing data")
            return false
        }
        return true
    }
    
    // MARK: - Prepare Data
    
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
    private func prepareMyChallengeDTO() async -> Bool {
        
        if statDTO.myChallenges.isEmpty {
            self.myChallenges = []
            return true
        }
        
        var challengeList = [MyChallengeDTO]()
        for index in statDTO.myChallenges {
            guard let challenge = self.challengeList[index] else {
                print("[ChallengeService] Failed to detected myChallenge: \(index)")
                return false
            }
            let progress = getUserProgress(with: challenge.type)
            challengeList.append(MyChallengeDTO(object: challenge, progress: progress))
        }
        self.myChallenges = challengeList.sorted{ $0.selectedAt < $1.selectedAt }
        return true
    }
    
    // prepare: Total Challenges
    private func prepareChallengeDTO() async -> Bool {
        
        for challenge in challengeList.values {
            if challenge.step == 1 {
                self.challengesDTO.append(mapFirstStepChallenge(with: challenge))
            } else {
                guard let previous = self.challengeList[challenge.challengeId - 1] else {
                    print("[ChallengeService] Failed to detected previous challengeData: \(challenge.challengeId - 1)")
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
    
    // Main
    func setMyChallenges(with challengeId: Int) async -> Bool {
        
        // inspection
        if !canAppendMyChallenge(with: challengeId) {
            print("[ChallengeService] Can't regist anymore myChallenges")
            return false
        }
        
        // prepare storage & local properties
        async let isDataFetched = fetchDataFromList(with: challengeId)
        async let isIndexFetched = fetchIndexFromArray(with: challengeId)
        let results = await [isDataFetched, isIndexFetched]
        
        guard results.allSatisfy({$0}) else {
            print("[ChallengeService] Unknown ChallengeId Detected")
            return false
        }
        let updatedAt = Date()
        
        // update process
        let context = localStorageManager.context
        return context.performAndWait {
            
            // update storage
            let results = [
                updateStatObjectAboutSet(context, with: challengeId),
                updateChallengeObjectAboutSet(context, with: challengeId, at: updatedAt)
            ]
            guard results.allSatisfy({ $0 }) else {
                print("[ChallengeService] Failed to update objects about set newChallenge")
                return false
            }
            
            // update context
            guard localStorageManager.saveContext() else {
                print("[ChallengeService] Failed to update context about set newMyChallenge")
                return false
            }
            
            // update local
            let progress = getUserProgress(with: self.challengeData.type)
            updateDTOAboutSet(with: challengeId, and: self.challengeData, also: progress)
            return true
        }
    }
    
    // Util
    private func canAppendMyChallenge(with challengeId: Int) -> Bool {
        return myChallenges.count < 3 &&
        statDTO.myChallenges.count < 3 &&
        !myChallenges.contains(where: { $0.challengeID == challengeId })
    }
    
    // Storage Upate
    private func updateChallengeObjectAboutSet(_ context: NSManagedObjectContext, with challengeId: Int, at updatedAt: Date) -> Bool {
        let userProgress = getUserProgress(with: challengeData.type)
        
        let updated = ChallengeUpdateDTO(
            challengeId: challengeId,
            userId: userId,
            newProgress: userProgress,
            newSelectStatus: true,
            newSelectedAt: updatedAt
        )
        do {
            return try challengeCD.updateObject(context: context, dto: updated)
        } catch {
            print("[ChallengeSC] Failed to detected challenge entity: \(error.localizedDescription)")
            return false
        }
    }
    
    // Storage Upate
    private func updateStatObjectAboutSet(_ context: NSManagedObjectContext, with challengeId: Int) -> Bool {
        var newMyChallenges = statDTO.myChallenges
        newMyChallenges.append(challengeId)
        
        let updated = StatUpdateDTO(
            userId: userId,
            newMyChallenges: newMyChallenges
        )
        do {
            return try statCD.updateObject(context: context, dto: updated)
        } catch {
            print("[ChallengeSC] Failed to detected stat entity: \(error.localizedDescription)")
            return false
        }
    }
    
    // Local Upate
    private func updateDTOAboutSet(with challengeId: Int, and object: ChallengeObject, also progress: Int) {
        self.statDTO.myChallenges.append(challengeId)
        self.myChallenges.append(MyChallengeDTO(object: object, progress: progress))
        self.challengesDTO[challengeDTOIndex].isSelected = true
    }
}

// MARK: - Disable myChallenge

extension ChallengeService {
    
    // Main
    func disableMyChallenge(with challengeId: Int) async -> Bool {
        
        // prepare storage & local properties
        async let isDataFetched = fetchDataFromList(with: challengeId)
        async let isIndexFetched = fetchIndexFromArray(with: challengeId)
        let results = await [isDataFetched, isIndexFetched]
        
        guard results.allSatisfy({$0}) else {
            print("[ChallengeService] Unknown ChallengeId Detected")
            return false
        }
        let updatedAt = Date()
        
        let context = localStorageManager.context
        return context.performAndWait {
            
            // update object
            let results = [
                updateStatObjectAboutDisable(context, with: challengeId),
                updateChallengeObjectAboutDisable(context, with: challengeId, at: updatedAt)
            ]
            guard results.allSatisfy({ $0 }) else {
                print("[ChallengeSC] Failed to update objects about disable myChallenge")
                return false
            }
            
            // update context
            guard localStorageManager.saveContext() else {
                print("[ChallengeSC] Failed to update context about disable myChallenge")
                return false
            }
            // update dto
            updateDTOAboutDisable(with: challengeId)
            return true
        }
    }
    
    // Storage Upate
    private func updateChallengeObjectAboutDisable(_ context: NSManagedObjectContext, with challengeId: Int, at updatedAt: Date) -> Bool {
        let updated = ChallengeUpdateDTO(
            challengeId: challengeId,
            userId: userId,
            newSelectStatus: false,
            newUnSelectedAt: updatedAt
        )
        do {
            return try challengeCD.updateObject(context: context, dto: updated)
        } catch {
            print("[ChallengeSC] Failed to detected challenge data: \(error.localizedDescription)")
            return false
        }
    }
    
    // Storage Upate
    private func updateStatObjectAboutDisable(_ context: NSManagedObjectContext, with challengeId: Int) -> Bool {
        var newMyChallenges = statDTO.myChallenges
        newMyChallenges.removeAll { $0 == challengeId }
        
        let updated = StatUpdateDTO(
            userId: userId,
            newMyChallenges: newMyChallenges
        )
        do {
            return try statCD.updateObject(context: context, dto: updated)
        } catch {
            print("[ChallengeSC] Failed to detected stat data: \(error.localizedDescription)")
            return false
        }
    }
    
    // Local Update
    private func updateDTOAboutDisable(with challengeId: Int) {
        self.statDTO.myChallenges.removeAll { $0 == challengeId }
        self.myChallenges.removeAll{ $0.challengeID == challengeId }
        self.challengesDTO[challengeDTOIndex].isSelected = false
    }
}

// MARK: - Reward myChallenge

extension ChallengeService {

    /// 완료한 도전과제에 대한 보상을 처리합니다.
    /// - Parameter challengeId: 보상을 받을 도전과제의 ID입니다.
    /// - Returns: 챌린지 완료에 따른 보상 정보를 `ChallengeRewardDTO`형태로 반환합니다.
    /// - Throws: 보상 처리 과정에서 발생한 오류를 던집니다.
    /// - 이 함수는 도전과제 보상을 지급하며, 해당 도전과제와 다음 도전과제의 상태를 업데이트합니다.
    /// - 또한 관련 통계 정보를 갱신하고, '나의 도전과제'에서 해당 도전과제를 해제합니다.
    /// - 모든 변경 사항 및 보상정보를 로그로 출력합니다.
    
    // Main
    func rewardMyChallenge(with challengeId: Int) async -> Bool {
        
        // prepare base data
        async let isDataFetched = fetchDataFromList(with: challengeId)
        async let isIndexFetched = fetchIndexFromArray(with: challengeId)
        let results = await [isDataFetched, isIndexFetched]
        
        guard results.allSatisfy({$0}) else {
            print("[ChallengeService] Invalid ChallengeId Detected")
            return false
        }
        
        let updatedAt = Date()
        let currentData = self.challengeData
        let currentIndex = self.challengeDTOIndex
        
        // inspection: step data
        guard checkNextData(with: self.challengeData) else {
            print("[ChallengeService] Failed to get next Challenge Data")
            return false
        }
        let context = localStorageManager.context
        
        // divide process
        if isFianlChallenge {
            
            // final: additional data not neccessary
            return finalChallengeRewardProcess(context, id: challengeId, data: currentData, index: currentIndex, updatedAt: updatedAt)
            
        } else {
            
            // mid: additional data require
            let nextId = self.challengeData.challengeId
            guard await fetchIndexFromArray(with: self.challengeData.challengeId) else {
                print("[ChallengeService] Invalid nextChallengeId Detected")
                return false
            }
            let nextIndex = self.challengeDTOIndex
            
            return midChallengeRewardProcess(context, currentId: challengeId, nextId: nextId, currentData: currentData, currentIndex: currentIndex, nextIndex: nextIndex, updatedAt: updatedAt)
        }
    }
    
    // Sub
    private func finalChallengeRewardProcess(_ context: NSManagedObjectContext, id: Int, data: ChallengeObject, index: Int, updatedAt: Date) -> Bool {
        
        var results = [Bool]()
        return context.performAndWait {
            
            // update storage
            results = [
                updateCurrentChallengeAboutReward(context, with: id, at: updatedAt),
                updateCurrentStatAboutReward(context, with: id, and: data)
            ]
            guard results.allSatisfy({ $0 }) else {
                print("[ChallengeService] Failed to update objects about reward myChallenge")
                return false
            }
            
            // update context
            guard localStorageManager.saveContext() else {
                print("[ChallengeService] Failed to update context about reward myChallenge")
                return false
            }
            
            // update local
            updateCurrentDTOAboutReward(with: id, and: index, at: updatedAt, and: data.reward)
            return true
        }
    }
    
    // Sub
    private func midChallengeRewardProcess(_ context: NSManagedObjectContext, currentId: Int, nextId: Int, currentData: ChallengeObject, currentIndex: Int, nextIndex: Int, updatedAt: Date) -> Bool {
        
        var results = [Bool]()
        return context.performAndWait{
            
            // update storage
            results = [
                updateCurrentChallengeAboutReward(context, with: currentId, at: updatedAt),
                updateCurrentStatAboutReward(context, with: currentId, and: currentData),
                updateNextChallengeAboutReward(context, with: nextId),
                updateNextStatAboutReward(context, with: currentData.step)
            ]
            guard results.allSatisfy({ $0 }) else {
                print("[ChallengeService] Failed to update objects about reward myChallenge")
                return false
            }
            
            // update context
            guard localStorageManager.saveContext() else {
                print("[ChallengeService] Failed to update context about reward myChallenge")
                return false
            }
            
            // update local
            updateCurrentDTOAboutReward(with: currentId, and: currentIndex, at: updatedAt, and: currentData.reward)
            updateNextDTOAboutReward(with: currentIndex, and: nextIndex, step: currentData.step)
            return true
        }
    }
    
    // Update challenge: current
    private func updateCurrentChallengeAboutReward(_ context: NSManagedObjectContext, with challengeId: Int,at updatedAt: Date) -> Bool {
        let updated = ChallengeUpdateDTO(
            challengeId: challengeId,
            userId: userId,
            newStatus: true,
            newSelectStatus: false,
            newUnSelectedAt: updatedAt,
            newFinishedAt: updatedAt
        )
        do {
            return try challengeCD.updateObject(context: context, dto: updated)
        } catch {
            print("[ChallengeSC] Failed to detected challenge data: \(error.localizedDescription)")
            return false
        }
    }
    
    // Update challenge: next
    private func updateNextChallengeAboutReward(_ context: NSManagedObjectContext, with challengeId: Int) -> Bool {
        
        let updated = ChallengeUpdateDTO(
            challengeId: challengeId,
            userId: userId,
            newLock: false
        )
        do {
            return try challengeCD.updateObject(context: context, dto: updated)
        } catch {
            print("[ChallengeService] Error detected while search entity: \(error.localizedDescription)")
            return false
        }
    }
    
    // Update stat: current
    private func updateCurrentStatAboutReward(_ context: NSManagedObjectContext, with challengeId: Int, and challengeData: ChallengeObject) -> Bool {
        
        var newMyChallenges = statDTO.myChallenges
        newMyChallenges.removeAll { $0 == challengeId }
        let newDrop = statDTO.drop + challengeData.reward
        
        let updated = StatUpdateDTO(
            userId: userId,
            newDrop: newDrop,
            newMyChallenges: newMyChallenges
        )
        do {
            return try statCD.updateObject(context: context, dto: updated)
        } catch {
            print("[ChallengeService] Failed to detected stat data: \(error.localizedDescription)")
            return false
        }
    }
    
    // Update stat: next
    private func updateNextStatAboutReward(_ context: NSManagedObjectContext, with step: Int) -> Bool {
        
        var newStep = statDTO.challengeStepStatus
        if let currentValue = newStep[step] {
            newStep[step] = currentValue + 1
        }
        let updated = StatUpdateDTO(
            userId: userId,
            newChallengeStepStatus: newStep
        )
        do {
            return try statCD.updateObject(context: context, dto: updated)
        } catch {
            print("[ChallengeService] Error detected while search entity: \(error.localizedDescription)")
            return false
        }
    }
    
    // Update local: current
    private func updateCurrentDTOAboutReward(with challengeId: Int, and index: Int, at updatedAt: Date, and reward: Int) {
        
        statDTO.drop += reward
        statDTO.myChallenges.removeAll{ $0 == challengeId }
        self.myChallenges.removeAll{ $0.challengeID == challengeId }
        
        self.challengesDTO[index].isSelected = false
        self.challengesDTO[index].isFinished = true
        self.challengesDTO[index].finishedAt = updatedAt
    }
    
    // Update local: next
    private func updateNextDTOAboutReward(with currentIndex: Int, and nextIndex: Int, step: Int) {
        
        if let currentValue = statDTO.challengeStepStatus[step] {
            statDTO.challengeStepStatus[step] = currentValue + 1
        }
        self.challengesDTO[nextIndex].islock = false
    }
    
    // Util: check next challenge
    private func checkNextData(with currentChallenge: ChallengeObject) -> Bool {
        
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
}

// MARK: Util

extension ChallengeService {
    
    private func fetchDataFromList(with challengeId: Int) async -> Bool {
        guard let data = challengeList[challengeId] else {
            print("[ChallengeService] Failed to search ChallengeData at List")
            return false
        }
        self.challengeData = data
        return true
    }
    
    private func fetchIndexFromArray(with challengeId: Int) async -> Bool {
        guard let index = challengesDTO.firstIndex(where: { $0.challengeId == challengeId}) else {
            print("[ChallengeService] Failed to search ChallengeIndex at List")
            return false
        }
        self.challengeDTOIndex = index
        return true
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
        let list = ChallengeList()
        
        switch type {
        case .onboarding:
            return 0
        case .serviceTerm:
            return list.getServiceTermSize()
        case .totalTodo:
            return list.getTotalTodoListSize()
        case .projectAlert:
            return list.getProjectAlertListSize()
        case .projectFinish:
            return list.getProjectFinishListSize()
        case .waterDrop:
            return list.getWaterDropListSize()
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
    
    init(object: ChallengeObject, progress: Int){
        self.challengeID = object.challengeId
        self.type = object.type
        self.title = object.title
        self.desc = object.desc
        self.goal = object.goal
        self.progress = progress
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
