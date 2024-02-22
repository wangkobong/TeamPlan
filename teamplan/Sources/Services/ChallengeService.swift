//
//  ChallengeService.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/10/10.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation

final class ChallengeService {
    
    //===============================
    // MARK: - Properties
    //===============================
    // for service
    private let challengeCD = ChallengeServicesCoredata()
    private let challengeLogCD = ChallengeLogServicesCoredata()
    private let statCD = StatisticsServicesCoredata()
    private let statCenter: StatisticsCenter
    private var userId: String
    
    // for log
    private let util = Utilities()
    private let logManager = LogManager()
    private let location = "ChallengeService"
    
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
        self.statCenter = StatisticsCenter(with: userId)
        self.statDTO = StatChallengeDTO()
        self.logManager.readyParameter(userId: userId, caller: "ChallengeService")
        util.log(.info, location, "Successfully initialize service", userId)
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
        try readyStatistics()
        challengeArray = try challengeCD.getChallenges(onwer: userId)
        try readyMyChallenge()
        try logManager.readyManager()
        util.log(.info, location, "Successfully ready service", userId)
    }
    
    //--------------------
    // Private Helper
    //--------------------
    // statistics
    private func readyStatistics() throws {
        guard let dto = try statCD.getStatisticsForDTO(with: userId, type: .challenge) as? StatChallengeDTO else {
            throw ChallengeError.UnexpectedGetStatDTOError
        }
        self.statDTO = dto
        try self.statCenter.readyCenter()
    }

    // myChallenge
    private func readyMyChallenge() throws {
        if !statDTO.myChallenge.isEmpty{
            for idx in statDTO.myChallenge {
                try setMyChallenges(with: idx)
            }
        }
    }
}

//===============================
// MARK: MyChallenge: Main
//===============================
extension ChallengeService {
    
    //--------------------
    // Get
    //--------------------
    /// 사용자의 '나의 도전과제' 목록을 반환합니다.
    /// - Returns:사용자의 챌린지 목록을 `MyChallengeDTO` 배열로 반환합니다.
    /// - 단, '나의 도전과제'를 지정하지 않은경우 '[]' 형태로 반환됩니다.
    func getMyChallenges() -> [MyChallengeDTO] {
        return self.myChallenges
    }
    
    //--------------------
    // Set
    //--------------------
    /// 특정 도전과제를 '나의 도전과제'로 등록합니다.
    /// - Parameter challengeId: '나의 도전과제'에 등록할 도전과제의 ID입니다.
    /// - Throws: 중복 도전과제, 최대 도전과제 수 초과 등으로 인한 오류를 던집니다.
    /// - 이 함수는 중복 검사를 수행하고, 도전과제를 'myChallenges'에 추가하며, 해당 도전과제의 상태를 업데이트합니다.
    /// - 또한 관련 통계 정보를 갱신하고, 모든 변경 사항을 로그로 출력합니다.
    func setMyChallenges(with challengeId: Int) throws {
        util.log(.info, location, "Check MyChallenge Duplication", userId)
        
        // check duplication
        let isDuplicated = try checkMyChallengeArray(with: challengeId)
        
        if !isDuplicated {
            util.log(.info, location, "MyChallenge duplication not detected, Proceed set process", userId)
            
            // core function
            try setCoreFunction(with: challengeId)
            util.log(.info, location, "Set core function - Complete", userId)
            
            // update & apply: challenge object
            try updateChallengeObject(with: challengeId, type: .set)
            util.log(.info, location, "Update challenge object - Complete", userId)
            
            // update & apply: statistics object
            try updateStatObject(type: .set)
            util.log(.info, location, "Update mychallenge at statistics - Complete", userId)
            
            // check: data inspection
            myChallengeDataInspection()
            util.log(.info, location, "Set MyChallenge - Complete", userId)
        }
        util.log(.info, location, "MyChallenge duplication detected", userId)
    }
    
    //-------------------------------
    // Disable
    //-------------------------------
    /// '나의 도전과제'로 등록된 특정 도전과제를 해제합니다.
    /// - Parameter challengeId: '나의 도전과제'에서 해제할 도전과제의 ID입니다.
    /// - Throws: 도전과제 해제 및 상태 업데이트에서 발생한 오류들을 던집니다.
    /// - 이 함수는 도전과제를 'myChallenges'에 제거하며, 해당 도전과제의 상태를 업데이트합니다.
    /// - 또한 관련 통계 정보를 갱신하고, 모든 변경 사항을 로그로 출력합니다.
    func disableMyChallenge(with challengeId: Int) throws {
        util.log(.info, location, "Disable MyChallenge - Start", userId)
        
        // core function
        disableCoreFunction(with: challengeId)
        util.log(.info, location, "Disable core function - Complete", userId)
        
        // apply: challenge object
        try updateChallengeObject(with: challengeId, type: .disable)
        util.log(.info, location, "Update challenge object - Complete", userId)
        
        // apply: statistics object
        try updateStatObject(type: .disable)
        util.log(.info, location, "Update mychallenge at statistics - Complete", userId)
        
        // check: data inspection
        myChallengeDataInspection()
        util.log(.info, location, "Disable MyChallenge - Complete", userId)
    }

    //-------------------------------
    // Reward
    //-------------------------------
    /// 완료한 도전과제에 대한 보상을 처리합니다.
    /// - Parameter challengeId: 보상을 받을 도전과제의 ID입니다.
    /// - Returns: 챌린지 완료에 따른 보상 정보를 `ChallengeRewardDTO`형태로 반환합니다.
    /// - Throws: 보상 처리 과정에서 발생한 오류를 던집니다.
    /// - 이 함수는 도전과제 보상을 지급하며, 해당 도전과제와 다음 도전과제의 상태를 업데이트합니다.
    /// - 또한 관련 통계 정보를 갱신하고, '나의 도전과제'에서 해당 도전과제를 해제합니다.
    /// - 모든 변경 사항 및 보상정보를 로그로 출력합니다.
    func rewardMyChallenge(with challengeId: Int) throws -> ChallengeRewardDTO {
        util.log(.info, location, "Reward MyChallenge - Start", userId)
        
        // update: local parameter
        let rewardDTO = try rewardCoreFunction(with: challengeId)
        util.log(.info, location, "Reward core function - Complete", userId)
        
        // apply: challenge object
        try updateChallengeObject(with: challengeId, type: .reward)
        util.log(.info, location, "Update challenge object - Complete", userId)
        
        // apply: statistics object
        try updateStatObject(type: .reward)
        util.log(.info, location, "Update mychallenge at statistics - Complete", userId)
        
        // disable: mychallenge
        try disableMyChallenge(with: challengeId)
        
        // check: data inspection
        rewardDataInsepction(with: rewardDTO)
        util.log(.info, location, "Reward MyChallenge - Complete", userId)
        
        return rewardDTO
    }
}

//===============================
// MARK: Challenge: Main
//===============================
extension ChallengeService {
    
    //-------------------------------
    // Get challenge index
    //-------------------------------
    /// 전체 도전과제 목록 정보를 제공합니다.
    /// - Returns: 도전과제 목록관련 정보들이 담긴 `ChallengeDTO` 타입의 배열을 반환합니다.
    /// - 이 함수는 도전과제 화면에서 도전과제 목록를 표시할 때 사용됩니다.
    /// - 목록을 표시하는데 필요한 정보만 담고있습니다.
    func getChallengeForIndex() -> [ChallengeDTO] {
        return challengeArray.map { ChallengeDTO(forIndex: $0) }
    }
     
    //-------------------------------
    // Get challenge detail
    //-------------------------------
    /// 특정 도전과제의 상세 정보를 제공합니다.
    /// - Parameter challengeId: 상세 정보를 조회할 도전과제 ID입니다.₩택했을 때, 해당 도전과제의 상세 정보를 표시하기 위해 사용됩니다.
    /// - 만약 해당 챌린지가 잠겨 있으면(`chlg_lock`), 이전 챌린지 정보도 함께 조회하여 반환합니다.
    /// - 이외 상황에서는 `ChallengeDTO`에 포함된 정보들을 중 일부를 사용하여 표현 가능합니다.
    func getChallengeForDetail(from challengeId: Int) throws -> ChallengeDTO {
        // get: challenge data
        let challengeData = try fetchChallenge(with: challengeId)
        
        // get: previous challenge data (lock case)
        let prevChallenge: ChallengeObject? = challengeData.chlg_lock ?
        try? getPrevChallenge(challengeType: challengeData.chlg_type, currentStep: challengeData.chlg_step) : nil
        
        // set: challengeDTO
        let challengeDTO = ChallengeDTO(forDetail: challengeData, previous: prevChallenge)
        
        // data inspection
        try challengeDataInspection(with: challengeDTO, needPrevious: challengeData.chlg_lock)
        return challengeDTO
    }
}

//===============================
// MARK: MyChallenge: Element
//===============================
extension ChallengeService {
    
    //-------------------------------
    // Set core function
    //-------------------------------
    /// 요청받은 도전과제를 '나의 도전과제' 에 추가하는 핵심기능 함수입니다.
    /// - Parameter challengeId: 추가할 도전과제의 ID입니다.
    /// - Throws: 도전과제 조회 실패할 경우 발생하는 오류를 던집니다.
    /// - 이 함수는 입력받은 ID를 기반으로 도전과제 상세정보와 관련 사용자 진행정보를 조회합니다.
    /// - 이후 조회한 정보를 기반으로 'MyChallengeDTO' 객체를 만들어 배열에 추가하고 관련 통계정보를 업데이트 합니다
    private func setCoreFunction(with challengeId: Int) throws {
        // get: challenge data
        let challengeData = try fetchChallenge(with: challengeId)
        // get: related user progress
        let userProgress = statCenter.getUserProgress(type: challengeData.chlg_type)
        // set: dto
        let dto = MyChallengeDTO(with: challengeData, and: userProgress)
        // apply: local parameter
        myChallenges.append(dto)
        statDTO.myChallenge.append(challengeId)
    }
    
    //-------------------------------
    // Disable core fuction
    //-------------------------------
    /// 요청받은 도전과제를 '나의 도전과제' 목록에서 제거하는 핵심기능 함수입니다.
    /// - Parameter challengeId: 제거할 도전과제의 ID입니다.
    /// - 이 함수는 입력받은 ID를 기반으로 '나의 챌린지' 목록에서 해당 도전과제를 탐색하고 제거합니다.
    private func disableCoreFunction(with challengeId: Int) {
        myChallenges.removeAll { $0.challengeID == challengeId }
        statDTO.myChallenge.removeAll { $0 == challengeId }
    }
    
    //-------------------------------
    // Reward core fuction
    //-------------------------------
    /// 요청받은 도전과제에 대한 보상을 처리하고 다음 도전과제를 잠금 해제합니다.
    /// - Parameter challengeId: 보상을 받을 도전과제의 ID입니다.
    /// - Returns: 보상 정보를 포함하는 `ChallengeRewardDTO` 객체를 반환합니다.
    /// - Throws: 도전과제 조회 및 다음 도전과제 조회 실패, 보상 처리 중 발생하는 오류를 던집니다.
    /// - 이 함수는 요청받은 도전과제와 다음 도전과제와 관련된 상세 정보를 조회합니다.
    /// - 조회한 정보를 기반으로 해당되는 보상을 처리하고, 도전과제 로그에 기록하며, 다음 도전과제를 잠금해제합니다.
    private func rewardCoreFunction(with challengeId: Int) throws  -> ChallengeRewardDTO {
        // get: extra challenge data
        let challengeData = try fetchChallenge(with: challengeId)
        let challengeType = challengeData.chlg_type.rawValue
        let nextChallengeData = try fetchNextChallenge(currentChallenge: challengeData, challengeId: challengeId)
        util.log(.info, location, "(reward core function) get related parameter - Compelete", userId)
        
        // update: statDTO (reward & challengeStep)
        statDTO.drop += challengeData.chlg_reward
        if let currentStep = statDTO.challengeStep[challengeType] {
            statDTO.challengeStep[challengeType] = currentStep + 1
        } else {
            throw ChallengeError.UnexpectedStepUpdateError
        }
        util.log(.info, location, "(reward core function) update statDTO - Compelete", userId)
        
        // update: challenge log
        try logManager.appendChallengeLog(with: challengeId, and: Date())
        util.log(.info, location, "(reward core function) update challengeLog - Compelete", userId)
        
        // update: challenge object (unlock next challenge)
        try updateChallengeObject(with: nextChallengeData.chlg_id, type: .next)
        util.log(.info, location, "(reward core function) update next challengeObject - Compelete", userId)
        
        return ChallengeRewardDTO(with: challengeData, and: nextChallengeData)
    }
}

//===============================
// MARK: Support
//===============================
extension ChallengeService {
    
    //-------------------------------
    // Fetch challenge object
    //-------------------------------
    private func fetchChallenge(with challengeId: Int) throws -> ChallengeObject {
        guard let challenge = challengeArray.first(where: { $0.chlg_id == challengeId }) else {
            throw ChallengeError.UnexpectedChallengeArrayError
        }
        return challenge
    }
    private func fetchNextChallenge(currentChallenge: ChallengeObject,challengeId: Int) throws -> ChallengeObject {
        if let nextChallenge = challengeArray.first(where: {
            ( $0.chlg_type == currentChallenge.chlg_type ) && ( $0.chlg_step == currentChallenge.chlg_step + 1 )
        }) {
            return nextChallenge
        } else {
            throw ChallengeError.NoMoreNextChallenge
        }
    }
    
    //-------------------------------
    // Check myChallenge array
    //-------------------------------
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
    
    //-------------------------------
    // Update challenge object
    //-------------------------------
    private func updateChallengeObject(with challengeId: Int, type: FunctionType) throws {
        let updatedDate = Date()
        
        // update: local storage
        switch type{
            
        case .set:
            let updated = ChallengeUpdateDTO(
                challengeId: challengeId, 
                userId: userId,
                newSelected: true,
                newSelectedAt: updatedDate
            )
            try challengeCD.updateChallenge(with: updated)
            
        case .disable:
            let updated = ChallengeUpdateDTO(
                challengeId: challengeId, 
                userId: userId,
                newSelected: false,
                newUnSelectedAt: updatedDate
            )
            try challengeCD.updateChallenge(with: updated)
            
        case .reward:
            let updated = ChallengeUpdateDTO(
                challengeId: challengeId, 
                userId: userId,
                newStatus: true,
                newFinishedAt: updatedDate
            )
            try challengeCD.updateChallenge(with: updated)
            
        case .next:
            let updated = ChallengeUpdateDTO(
                challengeId: challengeId, 
                userId: userId,
                newLock: false
            )
            try challengeCD.updateChallenge(with: updated)
        }
        // apply: service parameter
        challengeArray = try challengeCD.getChallenges(onwer: userId)
    }
    
    //-------------------------------
    // Update statistics object
    //-------------------------------
    private func updateStatObject(type: FunctionType) throws {
        
        // update: local storage
        switch type{
        case .reward:
            let updated = StatUpdateDTO(
                userId: userId,
                newDrop: statDTO.drop,
                newChallengeStep: statDTO.challengeStep
            )
            try statCD.updateStatistics(with: updated)
        default:
            let updated = StatUpdateDTO(
                userId: userId,
                newMyChallenge: statDTO.myChallenge
            )
            try statCD.updateStatistics(with: updated)
        }
        // apply: service parameter
        guard let dto = try statCD.getStatisticsForDTO(with: userId, type: .challenge) as? StatChallengeDTO else {
            throw ChallengeError.UnexpectedGetStatDTOError
        }
        self.statDTO = dto
    }
    
    //-------------------------------
    // Get previous challenge
    //-------------------------------
    func getPrevChallenge(challengeType: ChallengeType, currentStep: Int) throws -> ChallengeObject? {
        if currentStep <= 1 {
            return nil
        } else if let prevChallenge = challengeArray.first(
            where: { $0.chlg_type == challengeType && $0.chlg_step == currentStep - 1 }
        ) {
            return prevChallenge
        } else {
            throw ChallengeError.UnexpectedPrevChallengeSearchError
        }
    }
    
    //-------------------------------
    // Data inspection
    //-------------------------------
    // mychallenge
    private func myChallengeDataInspection() {
        util.log(.info, location, "Initialize myChallenge data inspection", userId)
        let log = """
            * ID: \(statDTO.userId)
            * WaterDrop: \(statDTO.drop)
            * ChallengeStep: \(statDTO.challengeStep)
            * MyChallengeID: \(statDTO.myChallenge)
            * MyChallengeCount: \(myChallenges.count)
            * ChallengeCount: \(challengeArray.count)
            """
        print(log)
    }
    
    // rewardDTO
    private func rewardDataInsepction(with dto: ChallengeRewardDTO) {
        util.log(.info, location, "Initialize rewardDTO data inspection", userId)
        let log = """
            * title: \(dto.title)
            * type: \(dto.type)
            * reward: \(dto.reward)
            * startAt: \(dto.setMyChallengeAt)
            * completeAt: \(dto.completeAt)
        """
        print(log)
    }
    
    // challengeDTO
    private func challengeDataInspection(with dto: ChallengeDTO, needPrevious: Bool) throws {
        util.log(.info, location, "Initialize challengeDTO data inspection", userId)
        var log = """
            * title: \(dto.title)
            * desc: \(dto.desc ?? "Nil detected")
            * goal: \(dto.goal ?? 0)
            * reward: \(dto.reward ?? 0)
            * step: \(dto.step ?? 0)
            * isUnlock: \(dto.isUnlock)
            * isSelected: \(dto.isSelected)
            * isComplete: \(dto.isComplete)
        """
        if needPrevious {
            let prevTitle = dto.prevTitle
            let prevDesc = dto.prevDesc
            let prevGoal = dto.prevGoal
            log += """
            * previousTitle: \(prevTitle ?? "Nil detected")
            * previousDesc: \(prevDesc ?? "Nil detected")
            * previousGoal: \(prevGoal ?? 0)
            """
        }
        print(log)
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


