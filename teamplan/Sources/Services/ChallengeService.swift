//
//  ChallengeService.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/10/10.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation

final class ChallengeService {
    
    private let controller = CoredataController()
    
    private let statCD: StatisticsServicesCoredata
    private let challengeCD: ChallengeServicesCoredata
    
    private var userId: String
    
    // shared
    @Published var myChallenges: [MyChallengeDTO] = []
    @Published var statDTO: StatChallengeDTO
    @Published var challengeArray: [ChallengeObject] = []
    
    //===============================
    // MARK: - Initializer
    //===============================
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
        self.statCD = StatisticsServicesCoredata(coredataController: controller)
        self.challengeCD = ChallengeServicesCoredata(coredataController: controller)
        
        self.statDTO = StatChallengeDTO()
    }
    
    /// `ChallengeService` 클래스 인스턴스의 추가 준비과정을 수행합니다.
    ///
    /// 이 추가 준비과정에서는 다음과 같은 작업이 수행됩니다:
    /// - 초기화된 `StatChallengeDTO`에 로컬 통계정보를 적용합니다
    /// - 통게정보에 저장된 '나의 도전과제' ID값들을 기반으로 'var myChallenges' 객체를 구성합니다. 단, 사용자가 나의 도전과제를 지정하지 않는경우 '[]' 형태로 구성됩니다.
    /// - 초기화된 'LogManager' 의 추가 준비과정을 수행합니다.
    ///
    /// 이 과정은 앱 내에서 도전과제 기능을 수행하기 위한 기본 설정을 제공합니다.
    func readyService() throws {
        challengeArray = try challengeCD.getObjects(with: userId)
        try initStatistics()
        try readyMyChallenge()
    }
    
    // statistics
    private func initStatistics() throws {
        self.statDTO = StatChallengeDTO(with: try statCD.getObject(with: userId))
    }

    // myChallenge
    private func readyMyChallenge() throws {
        if !statDTO.myChallenges.isEmpty{
            self.myChallenges = getMyChallenges()
        }
    }
}

struct StatChallengeDTO {
    
    let type: DTOType = .challenge
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
    init(with userId: String,
         ans drop: Int,
         chlgStep challengeStepStatus: [Int:Int],
         mychlg myChallenges: [Int]
    ){
        self.userId = userId
        self.drop = drop
        self.challengeStepStatus = challengeStepStatus
        self.myChallenges = myChallenges
    }
}

// MARK: MyChallenge
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

extension ChallengeService {
    
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
    
    // Get
    /// 사용자의 '나의 도전과제' 목록을 반환합니다.
    /// - Returns:사용자의 챌린지 목록을 `MyChallengeDTO` 배열로 반환합니다.
    /// - 단, '나의 도전과제'를 지정하지 않은경우 '[]' 형태로 반환됩니다.
    func getMyChallenges() -> [MyChallengeDTO] {
        var myChallenges: [MyChallengeDTO] = []
        for object in challengeArray {
            if object.selectStatus == true {
                myChallenges.append(MyChallengeDTO(with: object))
            }
        }
        return myChallenges
    }
    
    /// 특정 도전과제를 '나의 도전과제'로 등록합니다.
    /// - Parameter challengeId: '나의 도전과제'에 등록할 도전과제의 ID입니다.
    /// - Throws: 중복 도전과제, 최대 도전과제 수 초과 등으로 인한 오류를 던집니다.
    /// - 이 함수는 중복 검사를 수행하고, 도전과제를 'myChallenges'에 추가하며, 해당 도전과제의 상태를 업데이트합니다.
    /// - 또한 관련 통계 정보를 갱신하고, 모든 변경 사항을 로그로 출력합니다.
    func setMyChallenges(with challengeId: Int) throws {
        
        let isDuplicated = try checkMyChallengeArray(with: challengeId)
        
        if !isDuplicated {
            let challengeData = try fetchChallenge(with: challengeId)
            let userProgress = try getUserProgress(with: challengeData.type)
            try updateChallengeObject(with: challengeId, and: userProgress, type: .set)
            
            statDTO.myChallenges.append(challengeId)
            try updateStatObject(type: .set)
        }
    }
    
    /// '나의 도전과제'로 등록된 특정 도전과제를 해제합니다.
    /// - Parameter challengeId: '나의 도전과제'에서 해제할 도전과제의 ID입니다.
    /// - Throws: 도전과제 해제 및 상태 업데이트에서 발생한 오류들을 던집니다.
    /// - 이 함수는 도전과제를 'myChallenges'에 제거하며, 해당 도전과제의 상태를 업데이트합니다.
    /// - 또한 관련 통계 정보를 갱신하고, 모든 변경 사항을 로그로 출력합니다.
    func disableMyChallenge(with challengeId: Int) throws {
        
        myChallenges.removeAll { $0.challengeID == challengeId }
        try updateChallengeObject(with: challengeId, type: .disable)
        
        statDTO.myChallenges.removeAll { $0 == challengeId }
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
        
        let rewardDTO = try rewardCoreFunction(with: challengeId)
        
        try updateChallengeObject(with: challengeId, type: .reward)
        try updateStatObject(type: .reward)
        try disableMyChallenge(with: challengeId)
        
        return rewardDTO
    }
    private func rewardCoreFunction(with challengeId: Int) throws  -> ChallengeRewardDTO {
        
        let challengeData = try fetchChallenge(with: challengeId)
        let nextChallengeData = try fetchNextChallenge(currentChallenge: challengeData, challengeId: challengeId)
        try updateChallengeObject(with: nextChallengeData.challengeId, type: .next)
        
        // update drop & step
        statDTO.drop += challengeData.reward
        if let currentStep = statDTO.challengeStepStatus[challengeData.type.rawValue] {
            statDTO.challengeStepStatus[challengeData.type.rawValue] = currentStep + 1
        } else {
            throw ChallengeError.UnexpectedStepUpdateError
        }
        return ChallengeRewardDTO(with: challengeData, and: nextChallengeData)
    }
}


// MARK: Challenge
struct ChallengeDTO{

    // for index (essential)
    let id: Int
    let type: ChallengeType
    let title: String
    let isComplete: Bool
    let isSelected: Bool
    let isUnlock: Bool
    
    // for detail (optional)
    let desc: String?
    let goal: Int?
    let reward: Int?
    let step: Int?
    let completeAt: Date?
    
    let prevId: Int?
    let prevTitle: String?
    let prevDesc: String?
    let prevGoal: Int?
    
    // for log (optional)
    let setMyChallengeAt: Date?
    let disableMyChallengeAt: Date?
    
    // for index
    init(forIndex object: ChallengeObject){
        self.id = object.challengeId
        self.type = object.type
        self.title = object.title
        self.isComplete = object.status
        self.isSelected = object.selectStatus
        self.isUnlock = object.lock
        
        self.desc = nil
        self.goal = nil
        self.reward = nil
        self.step = nil
        self.completeAt = nil
        
        self.prevId = nil
        self.prevTitle = nil
        self.prevDesc = nil
        self.prevGoal = nil
        
        self.setMyChallengeAt = nil
        self.disableMyChallengeAt = nil
    }
    
    // for detail
    init(forDetail object: ChallengeObject, previous prevObject: ChallengeObject? = nil){
        self.id = object.challengeId
        self.type = object.type
        self.title = object.title
        self.isComplete = object.status
        self.isSelected = object.selectStatus
        self.isUnlock = object.lock
        
        self.desc = object.desc
        self.goal = Int(object.goal)
        self.reward = Int(object.reward)
        self.step = object.step
        self.completeAt = object.finishedAt
        
        self.prevId = prevObject?.challengeId
        self.prevTitle = prevObject?.title
        self.prevDesc = prevObject?.desc
        self.prevGoal = prevObject?.goal
        
        self.setMyChallengeAt = object.selectedAt
        self.disableMyChallengeAt = object.unselectedAt
    }
}

extension ChallengeService {
    
    /// 전체 도전과제 목록 정보를 제공합니다.
    /// - Returns: 도전과제 목록관련 정보들이 담긴 `ChallengeDTO` 타입의 배열을 반환합니다.
    /// - 이 함수는 도전과제 화면에서 도전과제 목록를 표시할 때 사용됩니다.
    /// - 목록을 표시하는데 필요한 정보만 담고있습니다.
    func getChallengeForIndex() -> [ChallengeDTO] {
        return challengeArray.map { ChallengeDTO(forIndex: $0) }
    }
     
    /// 특정 도전과제의 상세 정보를 제공합니다.
    /// - Parameter challengeId: 상세 정보를 조회할 도전과제 ID입니다.₩택했을 때, 해당 도전과제의 상세 정보를 표시하기 위해 사용됩니다.
    /// - 만약 해당 챌린지가 잠겨 있으면(`chlg_lock`), 이전 챌린지 정보도 함께 조회하여 반환합니다.
    /// - 이외 상황에서는 `ChallengeDTO`에 포함된 정보들을 중 일부를 사용하여 표현 가능합니다.
    func getChallengeForDetail(from challengeId: Int) throws -> ChallengeDTO {
        // get: challenge data
        let challengeData = try fetchChallenge(with: challengeId)
        
        // get: previous challenge data (lock case)
        let prevChallenge: ChallengeObject? = challengeData.lock ?
        try? getPrevChallenge(challengeType: challengeData.type, currentStep: challengeData.step) : nil
        
        let challengeDTO = ChallengeDTO(forDetail: challengeData, previous: prevChallenge)
        
        return challengeDTO
    }
}


// MARK: Update
extension ChallengeService {
    private func updateChallengeObject(with challengeId: Int, and userProgress: Int? = nil, type: FunctionType) throws {
        let updatedDate = Date()
        
        switch type{
        case .set:
            let updated = ChallengeUpdateDTO(
                challengeId: challengeId,
                userId: userId,
                newProgress: userProgress,
                newSelectStatus: true,
                newSelectedAt: updatedDate
            )
            try challengeCD.updateObject(with: updated)
            
        case .disable:
            let updated = ChallengeUpdateDTO(
                challengeId: challengeId,
                userId: userId,
                newSelectStatus: false,
                newUnSelectedAt: updatedDate
            )
            try challengeCD.updateObject(with: updated)
            
        case .reward:
            let updated = ChallengeUpdateDTO(
                challengeId: challengeId,
                userId: userId,
                newStatus: true,
                newSelectStatus: false,
                newFinishedAt: updatedDate
            )
            try challengeCD.updateObject(with: updated)
            
        case .next:
            let updated = ChallengeUpdateDTO(
                challengeId: challengeId,
                userId: userId,
                newLock: false
            )
            try challengeCD.updateObject(with: updated)
        }
        challengeArray = try challengeCD.getObjects(with: userId)
    }
    
    private func updateStatObject(type: FunctionType) throws {
        
        // update: local storage
        switch type{
        case .reward:
            let updated = StatUpdateDTO(
                userId: userId,
                newDrop: statDTO.drop,
                newChallengeStepStatus: statDTO.challengeStepStatus,
                newMyChallenges: statDTO.myChallenges
            )
            try statCD.updateObject(with: updated)
        default:
            let updated = StatUpdateDTO(
                userId: userId,
                newMyChallenges: statDTO.myChallenges
            )
            try statCD.updateObject(with: updated)
        }
        try initStatistics()
    }
}


// MARK: Util
extension ChallengeService {
    
    private func fetchChallenge(with challengeId: Int) throws -> ChallengeObject {
        guard let challenge = challengeArray.first(where: { $0.challengeId == challengeId }) else {
            throw ChallengeError.UnexpectedChallengeArrayError
        }
        return challenge
    }
    
    private func fetchNextChallenge(currentChallenge: ChallengeObject,challengeId: Int) throws -> ChallengeObject {
        if let nextChallenge = challengeArray.first(where: {
            ( $0.type == currentChallenge.type ) && ( $0.step == currentChallenge.step + 1 )
        }) {
            return nextChallenge
        } else {
            throw ChallengeError.NoMoreNextChallenge
        }
    }

    private func checkMyChallengeArray(with challengeId: Int) throws -> Bool {
        // check: size
        guard myChallenges.count < 3 else {
            throw ChallengeError.MyChallengeLimitExceeded
        }
        // check: duplication
        if myChallenges.contains(where: { $0.challengeID == challengeId }) {
            return true
        } else {
            return false
        }
    }

    func getPrevChallenge(challengeType: ChallengeType, currentStep: Int) throws -> ChallengeObject? {
        if currentStep <= 1 {
            return nil
        } else if let prevChallenge = challengeArray.first(
            where: { $0.type == challengeType && $0.step == currentStep - 1 }
        ) {
            return prevChallenge
        } else {
            throw ChallengeError.UnexpectedPrevChallengeSearchError
        }
    }
}

//===============================
// MARK: - Exception
//===============================
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

//===============================
// MARK: - Enum
//===============================
enum FunctionType {
    case set
    case disable
    case reward
    case next
}


