//
//  ChallengeService.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/10/10.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation

final class ChallengeService {

    private let statCD = StatisticsServicesCoredata()
    private let challengeCD = ChallengeServicesCoredata()
    
    private var userId: String
    private var challengeDict: [Int : ChallengeObject] = [:]
    private var challengeIdSet = Set<Int>()
    
    // shared
    @Published var statDTO: StatChallengeDTO
    @Published var myChallenges: [MyChallengeDTO] = []
    @Published var challengesDTO: [ChallengeDTO] = []
    
    // Legacy
    @Published var challengeArray: [ChallengeObject] = []
    
    /// `ChallengeService` 클래스의 인스턴스를 초기화합니다.
    ///
    /// 이 초기화 과정에서는 다음과 같은 작업이 수행됩니다:
    /// - 사용자 ID를 입력받은 'userId' 로 초기화 합니다.
    /// - 도전과제 기능에서 사용되는 통계정보 `StatChallengeDTO`를 기본형으로 초기화합니다.
    /// - 'ChallengeLog' 기록을 위한 'LogManager' 를 초기화합니다.
    ///
    /// 이 과정은 앱 내에서 도전과제 기능을 수행하기 위한 기본 설정을 제공합니다.
    init(with userId: String) {
        self.userId = userId        
        self.statDTO = StatChallengeDTO()
    }
}



// MARK: - Prepare Service
extension ChallengeService {

    // main executor
    func prepareService() async throws {
        let challenges = try await challengeCD.getObjects(with: userId)
        var tempDict = [Int: ChallengeObject]()
        
        for challenge in challenges where !challengeIdSet.contains(challenge.challengeId) {
            challengeIdSet.insert(challenge.challengeId)
            tempDict[challenge.challengeId] = challenge
        }
        challengeDict = tempDict
        statDTO = StatChallengeDTO(with: try statCD.getObject(with: userId))
        
        try await prepareChallenges()
        try await prepareMyChallenges()
        
        // legacy: must be replace to 'challengesDTO'
        self.challengeArray = challenges
    }
    
    // myChallenges
    private func prepareMyChallenges() async throws {
        // reset array
        myChallenges.removeAll()
        if statDTO.myChallenges.isEmpty { return }
        
        // fill array
        for idx in statDTO.myChallenges {
            guard let data = challengeDict[idx] else {
                throw ChallengeError.UnexpectedMyChallengeSearchError
            }
            myChallenges.append(MyChallengeDTO(with: data))
        }
    }
    
    // challenges
    private func prepareChallenges() async throws {
        challengesDTO = try challengeDict.values.map { challenge in
            if challenge.step == 1 {
                return mapFirstStepChallenge(with: challenge)
            } else {
                return try mapOtherStepChallenges(with: challenge)
            }
        }
    }
     
    // Struct ChallengeInfo: first step
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
    
   // Struct ChallengeInfo: other step (need previous info)
    private func mapOtherStepChallenges(with object: ChallengeObject) throws -> ChallengeDTO {
        guard let previous = challengeDict[object.challengeId - 1] else {
            throw ChallengeError.UnexpectedPrevChallengeSearchError
        }
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
            prevId: previous.challengeId,
            prevTitle: previous.title,
            prevDesc: previous.desc,
            prevGoal: previous.goal
        )
    }
}



// MARK: - MyChallenge CRUD
extension ChallengeService {
    
    /// 특정 도전과제를 '나의 도전과제'로 등록합니다.
    /// - Parameter challengeId: '나의 도전과제'에 등록할 도전과제의 ID입니다.
    /// - Throws: 중복 도전과제, 최대 도전과제 수 초과 등으로 인한 오류를 던집니다.
    /// - 이 함수는 중복 검사를 수행하고, 도전과제를 'myChallenges'에 추가하며, 해당 도전과제의 상태를 업데이트합니다.
    /// - 또한 관련 통계 정보를 갱신하고, 모든 변경 사항을 로그로 출력합니다.
    func setMyChallenges(with challengeId: Int) throws {
        
        if canAppendMyChallenge(with: challengeId) {
            // properties
            let updatedAt = Date()
            let data = try getDataFromChallengeDict(with: challengeId)
            let userProgress = try getUserProgress(with: data.type)
            
            // DTO
            try updateMyChallengeDTO(with: challengeId, type: .set)
            try updateChallengeDTO(with: challengeId, type: .set)
            try updateChallengeStatDTO(with: challengeId, type: .set)
            
            // Object
            try updateChallengeObject(with: challengeId, userProgress: userProgress, type: .set, at: updatedAt)
            try updateStatObject(type: .set)
        }
    }
    
    /// 사용자의 '나의 도전과제' 목록을 반환합니다.
    /// - Returns:사용자의 챌린지 목록을 `MyChallengeDTO` 배열로 반환합니다.
    /// - 단, '나의 도전과제'를 지정하지 않은경우 '[]' 형태로 반환됩니다.
    func getMyChallenges() throws -> [MyChallengeDTO] {
        // myChallenge check
        if statDTO.myChallenges.isEmpty { return [] }
        var updatedArray: [MyChallengeDTO] = []
        
        // fill array
        for idx in statDTO.myChallenges {
            guard let data = challengeDict[idx] else {
                throw ChallengeError.UnexpectedMyChallengeSearchError
            }
            updatedArray.append(MyChallengeDTO(with: data))
        }
        myChallenges = updatedArray
        return myChallenges
    }
    
    /// 전체 도전과제 목록 정보를 제공합니다.
    /// - Returns: 도전과제 목록관련 정보들이 담긴 `ChallengeDTO` 타입의 배열을 반환합니다.
    /// - 이 함수는 도전과제 화면에서 도전과제 목록를 표시할 때 사용됩니다.
    /// - 목록을 표시하는데 필요한 정보만 담고있습니다.
    func getChallenges() throws -> [ChallengeDTO] {
        return challengesDTO
    }
    
    /// '나의 도전과제'로 등록된 특정 도전과제를 해제합니다.
    /// - Parameter challengeId: '나의 도전과제'에서 해제할 도전과제의 ID입니다.
    /// - Throws: 도전과제 해제 및 상태 업데이트에서 발생한 오류들을 던집니다.
    /// - 이 함수는 도전과제를 'myChallenges'에 제거하며, 해당 도전과제의 상태를 업데이트합니다.
    /// - 또한 관련 통계 정보를 갱신하고, 모든 변경 사항을 로그로 출력합니다.
    func disableMyChallenge(with challengeId: Int) throws {
        // properties
        let updatedAt = Date()
        
        // DTO
        try updateMyChallengeDTO(with: challengeId, type: .disable)
        try updateChallengeDTO(with: challengeId, type: .disable)
        try updateChallengeStatDTO(with: challengeId, type: .disable)

        // Object
        try updateChallengeObject(with: challengeId, type: .disable, at: updatedAt)
        try updateStatObject(type: .disable)
    }

    /// 완료한 도전과제에 대한 보상을 처리합니다.
    /// - Parameter challengeId: 보상을 받을 도전과제의 ID입니다.
    /// - Returns: 챌린지 완료에 따른 보상 정보를 `ChallengeRewardDTO`형태로 반환합니다.
    /// - Throws: 보상 처리 과정에서 발생한 오류를 던집니다.
    /// - 이 함수는 도전과제 보상을 지급하며, 해당 도전과제와 다음 도전과제의 상태를 업데이트합니다.
    /// - 또한 관련 통계 정보를 갱신하고, '나의 도전과제'에서 해당 도전과제를 해제합니다.
    /// - 모든 변경 사항 및 보상정보를 로그로 출력합니다.
    func rewardMyChallenge(with challengeId: Int) throws -> ChallengeRewardDTO {
        // properties
        let updatedAt = Date()
        let currentChallenge = try getDataFromChallengeDict(with: challengeId)
        let nextChallengeId = try getNextChallengeId(with: currentChallenge)
        let nextChallenge = try getDataFromChallengeDict(with: nextChallengeId)
        
        // DTO
        try updateMyChallengeDTO(with: challengeId, type: .reward)
        try updateChallengeDTO(with: challengeId, type: .reward, finishedAt: updatedAt)
        try updateChallengeStatDTO(with: challengeId, type: .reward)
        
        // Object
        try updateChallengeObject(with: challengeId, type: .reward, at: updatedAt)
        try updateChallengeObject(with: nextChallengeId, type: .next, at: updatedAt)
        try updateStatObject(type: .reward)
        
        return ChallengeRewardDTO(with: currentChallenge, and: nextChallenge)
    }
}



// MARK: Update DTO
enum FunctionType {
    case set
    case disable
    case reward
    case next
}

extension ChallengeService {
    
    // MyChallengeDTO
    private func updateMyChallengeDTO(with challengeId: Int, type: FunctionType) throws {
        switch type {
        case .set:
            let dto = MyChallengeDTO(with: try getDataFromChallengeDict(with: challengeId))
            self.myChallenges.append(dto)
            
        case .disable, .reward:
            self.myChallenges.removeAll { $0.challengeID == challengeId }
            
        case .next:
            break
        }
    }
    
    // ChallengeDTO
    private func updateChallengeDTO(with challengeId: Int, type: FunctionType, finishedAt: Date? = nil) throws {
        let index = try getChallengeDictIndex(with: challengeId)
        
        switch type {
        case .set:
            challengesDTO[index].isSelected = true
            
        case .disable:
            challengesDTO[index].isSelected = false
            
        case .reward:
            challengesDTO[index].isSelected = false
            challengesDTO[index].isFinished = true
            challengesDTO[index].finishedAt = finishedAt
            
        case .next:
            break
        }
    }
    
    // StatDTO
    private func updateChallengeStatDTO(with challengeId: Int, type: FunctionType) throws {
        switch type {
        case .set:
            statDTO.myChallenges.append(challengeId)
            
        case .disable:
            statDTO.myChallenges.removeAll { $0 == challengeId }
            
        case .reward:
            let data = try getDataFromChallengeDict(with: challengeId)
            
            statDTO.drop += data.reward
            statDTO.myChallenges.removeAll { $0 == challengeId }
            if let currentStep = statDTO.challengeStepStatus[data.type.rawValue] {
                statDTO.challengeStepStatus[data.type.rawValue] = currentStep + 1
            } else {
                throw ChallengeError.UnexpectedGetStatDTOError
            }
            
        case .next:
            break
        }
    }
}
    

// MARK: Update Object
extension ChallengeService {
    
    private func updateChallengeObject(with challengeId: Int, userProgress: Int? = nil, type: FunctionType, at updatedAt: Date) throws {
        var updated = ChallengeUpdateDTO(challengeId: challengeId, userId: userId)
        
        switch type{
        case .set:
            updated.newProgress = userProgress
            updated.newSelectStatus = true
            updated.newSelectedAt = updatedAt
            print(updated)
            
        case .disable:
            updated.newStatus = false
            updated.newUnSelectedAt = updatedAt
            
        case .reward:
            updated.newStatus = true
            updated.newSelectStatus = false
            updated.newFinishedAt = updatedAt
            
        case .next:
            updated.newLock = false
        }
        try challengeCD.updateObject(with: updated)
    }
    
    private func updateStatObject(type: FunctionType) throws {
        var updated = StatUpdateDTO(userId: userId)
        
        switch type{
            
        case .set, .disable:
            updated.newMyChallenges = statDTO.myChallenges
            
        case .reward:
            updated.newDrop = statDTO.drop
            updated.newMyChallenges = statDTO.myChallenges
            updated.newChallengeStepStatus = statDTO.challengeStepStatus
            
        case .next:
            break
        }
        try statCD.updateObject(with: updated)
    }
}


// MARK: Util
extension ChallengeService {
    
    private func canAppendMyChallenge(with challengeId: Int) -> Bool {
        return myChallenges.count < 3 && !myChallenges.contains(where: { $0.challengeID == challengeId })
    }
    
    private func getChallengeDictIndex(with challengeId: Int) throws -> Int {
        guard let index = challengesDTO.firstIndex(where: { $0.challengeId == challengeId}) else {
            throw ChallengeError.UnexpectedChallengeArrayError
        }
        return index
    }
    
    private func getDataFromChallengeDict(with challengeId: Int) throws -> ChallengeObject {
        guard let data = challengeDict[challengeId] else {
            throw ChallengeError.UnexpectedChallengeArrayError
        }
        return data
    }
    
    private func getNextChallengeId(with currentChallenge: ChallengeObject) throws -> Int {
        if let nextChallenge = challengeDict.values.first(where: {
            ( $0.type == currentChallenge.type ) && ( $0.step == currentChallenge.step + 1 )
        }) {
            return nextChallenge.challengeId
        } else {
            throw ChallengeError.NoMoreNextChallenge
        }
    }
    
    private func getUserProgress(with type: ChallengeType) throws -> Int {
        let stat = try statCD.getObject(with: userId)
        switch type {
        case .onboarding:
            return 1
        case .serviceTerm:
            return stat.term
        case .totalTodo:
            return stat.totalRegistedTodos
        case .projectAlert:
            return stat.totalAlertedProjects
        case .projectFinish:
            return stat.totalFinishedProjects
        case .waterDrop:
            return stat.drop
        case .unknownType:
            return 0
        }
    }
}


// MARK: ChallengeDTO
public struct ChallengeDTO: Equatable {

    var challengeId: Int
    let title: String
    let desc: String
    let goal: Int
    let type: ChallengeType
    let reward: Int
    let step: Int
    
    var isFinished: Bool
    var isSelected: Bool
    var isUnlock: Bool
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
        self.isUnlock = isUnlock
        self.finishedAt = finishedAt
        self.prevId = prevId
        self.prevTitle = prevTitle
        self.prevDesc = prevDesc
        self.prevGoal = prevGoal
    }
}


// MARK: MyChallengeDTO
struct MyChallengeDTO: Hashable, Identifiable {

    let id = UUID().uuidString
    var challengeID: Int
    let type: ChallengeType
    let title: String
    let desc: String
    let goal: Int
    let progress: Int
    
    init(with object: ChallengeObject){
        self.challengeID = object.challengeId
        self.type = object.type
        self.title = object.title
        self.desc = object.desc
        self.goal = object.goal
        self.progress = object.progress
    }
}


// MARK: - StatChallengeDTO
struct StatChallengeDTO {
    
    let userId: String
    var drop: Int
    var challengeStepStatus: [Int : Int]
    var myChallenges: [Int]
    
    init(){
        self.userId = ""
        self.drop = 0
        self.challengeStepStatus = [ : ]
        self.myChallenges = []
    }
    init(with object: StatisticsObject){
        self.userId = object.userId
        self.drop = object.drop
        self.challengeStepStatus = object.challengeStepStatus
        self.myChallenges = object.mychallenges
    }
}


// MARK: - ChallengeRewardDTO
struct ChallengeRewardDTO {

    let title: String
    let desc: String
    let type: ChallengeType
    let reward: Int
    let setMyChallengeAt: Date
    let completeAt: Date
    
    init(with object: ChallengeObject, and nextObject: ChallengeObject) {
        self.title = nextObject.title
        self.desc = nextObject.desc
        self.type = nextObject.type
        self.reward = object.reward
        self.setMyChallengeAt = object.selectedAt
        self.completeAt = object.finishedAt
    }
}


// MARK: - Exception
enum ChallengeError: LocalizedError {
    case UnexpectedGetStatDTOError
    case UnexpectedChallengeArrayError
    case UnexpectedMyChallengeSearchError
    case UnexpectedPrevChallengeSearchError
    case UnexpectedStepUpdateError
    case UnexpectedChallengeDataInspectionError
    case MyChallengeLimitExceeded
    case NoMoreNextChallenge
    
    var errorDescription: String?{
        switch self {
        case .MyChallengeLimitExceeded:
            return "[Critical]ChallengeService - Throw: MyChallenge limit exceeded"
        case .UnexpectedGetStatDTOError:
            return "[Critical]ChallengeService - Throw: There was an unexpected error while Get StatDTO"
        case .UnexpectedChallengeArrayError:
            return "[Critical]ChallengeService - Throw: There was an unexpected error while get challenge from array"
        case .UnexpectedMyChallengeSearchError:
            return "[Critical]ChallengeService - Throw: There was an unexpected error while search myChallenge"
        case .UnexpectedPrevChallengeSearchError:
            return "[Critical]ChallengeService - Throw: There was an unexpected error while search previousChallenge"
        case .UnexpectedChallengeDataInspectionError:
            return "[Critical]ChallengeService - Throw: There was an unexpected error while processing challenge data inspection"
        case .UnexpectedStepUpdateError:
            return "[Critical]ChallengeService - Throw: There was an unexpected error while update challengeStep"
        case .NoMoreNextChallenge:
            return "[Critical]ChallengeService - Throw: No more Available Challenge"
        }
    }
}
