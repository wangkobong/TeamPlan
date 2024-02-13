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
    // MARK: - Parameter
    //===============================
    // reference
    let challengeCD = ChallengeServicesCoredata()
    let challengeLogCD = ChallengeLogServicesCoredata()
    let statCD = StatisticsServicesCoredata()
    let logManager = LogManager()
    let util = Utilities()
    
    // private
    private var userId: String
    private let statCenter: StatisticsCenter
    
    // private: log
    private let location = "ChallengeService"
    
    // shared
    @Published var myChallenges: [MyChallengeDTO] = []
    @Published var statDTO: StatChallengeDTO
    @Published var challengeArray: [ChallengeObject] = []
    
    //===============================
    // MARK: - Constructor
    //===============================
    init(with userId: String) {
        self.userId = userId
        self.statCenter = StatisticsCenter(with: userId)
        self.statDTO = StatChallengeDTO()
        self.logManager.readyParameter(userId: userId, caller: "ChallengeService")
        util.log(.info, location, "Successfully initialize service", userId)
    }
    
    // executor
    func readyService() throws {
        try readyStatistics()
        challengeArray = try challengeCD.getChallenges(onwer: userId)
        try readyMyChallenge()
        try logManager.readyManager()
        util.log(.info, location, "Successfully ready service", userId)
    }
    
    // element: statistics
    private func readyStatistics() throws {
        guard let dto = try statCD.getStatisticsForDTO(with: userId, type: .challenge) as? StatChallengeDTO else {
            throw ChallengeError.UnexpectedGetStatDTOError
        }
        self.statDTO = dto
        try self.statCenter.readyCenter()
    }
    
    // element: myChallenge
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
    func getMyChallenges() throws -> [MyChallengeDTO] {
        return self.myChallenges
    }
    
    //--------------------
    // Set
    // * function only update related object
    // * for apply update, call 'getMyChallenges' function or 'myChallenges' array after 'Set'
    //--------------------
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
    // * function only update related object
    // * for apply update, call 'getMyChallenges' function or 'myChallenges' array after 'Disable'
    //-------------------------------
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
    // * function only update related object
    // * for apply update, call 'getMyChallenges' function or 'myChallenges' array after 'Reward'
    //-------------------------------
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
    // Get challenge: for index
    //-------------------------------
    func getChallengeForIndex() -> [ChallengeDTO] {
        return challengeArray.map { ChallengeDTO(forIndex: $0) }
    }
     
    //-------------------------------
    // Get challenge: for detail
    //-------------------------------
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
    private func disableCoreFunction(with challengeId: Int) {
            myChallenges.removeAll { $0.challengeID == challengeId }
            statDTO.myChallenge.removeAll { $0 == challengeId }
    }
    
    //-------------------------------
    // Reward core fuction
    //-------------------------------
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


