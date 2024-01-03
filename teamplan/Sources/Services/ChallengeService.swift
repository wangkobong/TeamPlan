//
//  ChallengeService.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/10/10.
//  Copyright © 2023 team1os. All rights reserved.
//
// -------------------------------
// ChallengeService Code Instructions
// -------------------------------
// #Notice
//  * After initialization (init()), it is essential to call 'readyService()'.
//  * There is no need to recall 'readyService()' after the initial call.
//  * ChallengeService does not maintain '[ChallengeDTO]' persistently.
//  * To update '[ChallengeDTO]', please invoke 'getChallenges()' again.

// -------------------------------
// 1. Initialize ChallengeService
// -------------------------------
// #Example:
// let chlgService = ChallengeService(with: Identifier)
// chlgService.readyService()


// -------------------------------
// 2. MyChallenge Functionality
// -------------------------------
// < Get My Challenges >
// #Example:
// let myChallenge = chlgService.getMyChallenges()
// #Returns: [MyChallengeDTO]


// < Set My Challenges >
// #Example:
// chlgService.setMyChallenges(with: ChallengeID)

// #Includes updates for:
//  * myChallenges: [MyChallengeDTO]
//  * statDTO: StatChallengeDTO.stat_mychlg
//  * ChallengeDTO: MyChallenge Related Status


// < Disable My Challenge >
// #Example:
// chlgService.disableMyChallenge(with: ChallengeID)

// #Includes updates for:
//  * myChallenges: [MyChallengeDTO]
//  * statDTO: StatChallengeDTO.stat_mychlg
//  * ChallengeDTO: MyChallenge Related Status


// < Reward My Challenge >
// #Example:
// let rewardInfo = chlgService.rewardMyChallenge(with: ChallengeID)
// #Returns: ChallengeRewardDTO

// #Notice:
//  * This function does not include the capability to identify eligible challenges for rewards.
//  * It focuses solely on updating the challenge status and generating reward information.

// #Includes updates for:
//  * myChallenges: [MyChallengeDTO]
//  * statDTO: StatChallengeDTO.stat_mychlg
//  * ChallengeDTO: MyChallenge Related Status


// -------------------------------
// 3. Challenge Functionality
// -------------------------------
// < Get Challenges >
// #Example
// let challegnes = chlgService.getChallenges()
// #Returns: [ChallengeDTO]


// < Get Challenge >
// let challenge = chlgService.getChallenge(with: challengeId)
// #Returns: ChallengeDTO



import Foundation

final class ChallengeService {
    
    //===============================
    // MARK: - Parameter
    //===============================
    let challengeCD = ChallengeServicesCoredata()
    let challengeLogCD = ChallengeLogServicesCoredata()
    let statCD = StatisticsServicesCoredata()
    
    var userId: String
    let statCenter: StatisticsCenter
    
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
    }
    // Init function
    func readyService() throws {
        // Step1. get Statistics
        try readyStatistics()
        // Step2. get Challenges
        challengeArray = try challengeCD.getChallenges(onwer: userId)
        // Step3. get MyChallenge
        try readyMyChallenge()
    }
    // Init Statistics
    private func readyStatistics() throws {
        // Step1. Ready to Use ChallengeStatisticsDTO
        guard let dto = try statCD.getStatisticsForDTO(with: userId, type: .challenge) as? StatChallengeDTO else {
            throw ChallengeError.UnexpectedGetError
        }
        self.statDTO = dto
        // Step2. Ready to Use ChallengeStatisticsCenter
        try self.statCenter.readyCenter()
    }
    // Init MyChallenge
    private func readyMyChallenge() throws {
        // Step1. Check MyChallenge Empty Case
        if !statDTO.stat_mychlg.isEmpty{
            
            // Step2. Filled MyChallenge Array with Statistics Data
            for idx in statDTO.stat_mychlg {
                try setMyChallenges(with: idx)
            }
        }
    }
}
//===============================
// MARK: MyChallenges
//===============================
extension ChallengeService {

    //--------------------
    // Set MyChallenge
    //--------------------
    func setMyChallenges(with challengeId: Int) throws {
        // Step1. Check MyChallenge And Add Challenge
        let isDuplicated = try checkMyChallengeAndAppend(with: challengeId)
        
        if !isDuplicated {
            // Step3.  Apply Challenge Update
            try updateChallengeStatus(with: challengeId, type: .set)
            // Step4. Apply Statistics Update
            try updateStatistics()
            challengeArray = try challengeCD.getChallenges(onwer: userId)
        }
    }
    
    //--------------------
    // Get MyChallenge
    //--------------------
    func getMyChallenges() throws -> [MyChallengeDTO] {
        return self.myChallenges
    }
    
    //-------------------------------
    // (Update) Disable MyChallenge
    //-------------------------------
    func disableMyChallenge(with challengeId: Int) throws {
        // Step1. Remove MyChallenge at Array
        removeChallengeFromArrays(with: challengeId)
        
        // Step2. Apply Challenge Update
        try updateChallengeStatus(with: challengeId, type: .disable)

        // Step3. Apply Statistics Update
        try updateStatistics()
        challengeArray = try challengeCD.getChallenges(onwer: userId)
    }
    
    //-------------------------------
    // (Update) Reward MyChallenge
    //-------------------------------
    func rewardMyChallenge(with challengeId: Int) throws -> ChallengeRewardDTO {
        // Step1. Processing Challenge Reward
        try rewardProcess(with: challengeId)
        
        // Step2. Apply Challenge Update (Reward)
        try updateChallengeStatus(with: challengeId, type: .reward)
        
        // Step3. Apply Statistics Update
        try updateStatistics()
        
        // Step4. Update Challenge (Next)
        let rewardDTO = try updateNextChallenge(with: challengeId)
        
        return rewardDTO
    }
    
    // * Core Process
    private func rewardProcess(with challengeId: Int) throws {
        // Step1. Search Additional Challenge Data
        let challenge = try fetchChallenge(with: challengeId)
        
        // Step2. Update Statistics
        statDTO.stat_drop += challenge.chlg_reward
        
        // Step3. Update Challenge Step
        try updateChallengeStep(with: challenge)

        // Step4. Remove Challenge from 'MyChallenge'
        removeChallengeFromArrays(with: challengeId)
        
        // Step5. ChallengeLog Record
        try updatedChallengeLog(with: challengeId)
    }
    
    //-------------------------------
    // Update Function
    //-------------------------------
    // * Update Challenge Status
    private func updateChallengeStatus(with challengeId: Int, type: functionType) throws {
        // Step1. Search Additional Challenge Data
        let challenge = try fetchChallenge(with: challengeId)
        // Step2. Struct UpdateDTO
        var updatedStatus = ChallengeStatusDTO(with: challenge)
        let updatedDate = Date()
        
        // Step3. Update by Type
        switch type{
        case .set:
            updatedStatus.updateSelected(with: true)
            updatedStatus.updateSelectedAt(with: updatedDate)
        case .disable:
            updatedStatus.updateSelected(with: false)
            updatedStatus.updateUnselectedAt(with: updatedDate)
        case .reward:
            updatedStatus.updateStatus(with: true)
            updatedStatus.updateFinishedAt(with: updatedDate)
            updatedStatus.updateSelected(with: false)
        case .next:
            updatedStatus.updateLock(with: false)
        }
        // Step4. Update with DTO
        try challengeCD.updateChallenge(with: updatedStatus)
    }
    
    // * Statistics Update
    private func updateStatistics() throws {
        let updatedStatistics = StatUpdateDTO(challengeDTO: statDTO)
        try statCD.updateStatistics(with: updatedStatistics)
    }
    
    // * Challenge Log Update
    private func updatedChallengeLog(with challengeId: Int) throws {
        try challengeLogCD.updateLog(with: userId, challenge: challengeId, updatedAt: Date())
    }
    
    // * Challenge Step Update
    private func updateChallengeStep(with challenge: ChallengeObject) throws {
        let challengeType = challenge.chlg_type.rawValue
        if let currentVal = statDTO.stat_chlg_step[challengeType] {
            statDTO.stat_chlg_step[challengeType] = currentVal + 1
        } else {
            throw ChallengeError.UnexpectedStepUpdateError
        }
    }
    
    // * Next Challenge Update
    private func updateNextChallenge(with challengeId: Int) throws -> ChallengeRewardDTO {
        let currentChallenge = try fetchChallenge(with: challengeId)
        let nextChallenge = try findNextChallenge(with: challengeId)
        
        try updateChallengeStatus(with: nextChallenge.chlg_id, type: .next)
        
        return ChallengeRewardDTO(with: currentChallenge, and: nextChallenge)
    }

    //-------------------------------
    // Helper Function
    //-------------------------------
    // * Fetch Challenge
    private func fetchChallenge(with challengeId: Int) throws -> ChallengeObject {
        guard let challenge = challengeArray.first(where: { $0.chlg_id == challengeId }) else {
            throw ChallengeError.UnexpectedChallengeArrayError
        }
        return challenge
    }
    
    // * Add Challenge to 'MyChallenge' Array
    private func addToMyChallenge(with challengeId: Int) throws {
        // Step1. Get Challenge from ChallengeArray
        let myChallenge = try fetchChallenge(with: challengeId)
        // Step2. Get UserProgress
        let userProgress = statCenter.getUserProgress(type: myChallenge.chlg_type)
        // Step3. Struct MyChallengeDTO
        let dto = MyChallengeDTO(with: myChallenge, and: userProgress)
        // Step4. Append MyChallenge
        myChallenges.append(dto)
        statDTO.stat_mychlg.append(challengeId)
    }

    // * Remove challenge from arrays
    private func removeChallengeFromArrays(with challengeId: Int) {
        myChallenges.removeAll { $0.challengeID == challengeId }
        statDTO.stat_mychlg.removeAll { $0 == challengeId }
    }
    
    // * Find Next Challenge ID
    private func findNextChallenge(with challengeId: Int) throws -> ChallengeObject {
        // Step1. Search Additional Challenge Data
        let currentChallenge = try fetchChallenge(with: challengeId)
        // Step2. Search Next Challenge Data
        if let nextChallenge = challengeArray.first(where: {
            $0.chlg_type == currentChallenge.chlg_type && $0.chlg_step == currentChallenge.chlg_step + 1
        }) {
            return nextChallenge
        } else {
            throw ChallengeError.NoMoreNextChallenge
        }
    }
    
    // * MyChallenge Duplicate test
    private func checkMyChallengeAndAppend(with inputId: Int) throws -> Bool {
        // Step1. MyChallenges Size Check
        guard myChallenges.count < 3 else {
            throw ChallengeError.MyChallengeLimitExceeded
        }
        // Step2. Duplicated ChallengeID Check
        if myChallenges.contains(where: { $0.challengeID == inputId }) {
            return true
        } else {
            try addToMyChallenge(with: inputId)
            return false
        }
    }
}


//===============================
// MARK: Challenge
//===============================
extension ChallengeService {
    
    //-------------------------------
    // Get Challenges
    //-------------------------------
    func getChallenges() throws -> [ChallengeDTO] {
        challengeArray = try challengeCD.getChallenges(onwer: userId)
        return challengeArray.map { ChallengeDTO(with: $0) }
    }
     
    //-------------------------------
    // Get Challenge
    //-------------------------------
    func getChallenge(from challengeId: Int) throws -> ChallengeDTO {
        
        // Step1. Fetch Challenge
        let challenge = try fetchChallenge(with: challengeId)
        
        // Step2. Fetch Prev Challenge
        guard let prevChallenge = try getPrevChallenge(challengeType: challenge.chlg_type, currentStep: challenge.chlg_step) else {
            return ChallengeDTO(with: challenge)
        }
        return ChallengeDTO(with: challenge, and: prevChallenge)
    }
}

//===============================
// MARK: - Support Func
//===============================
extension ChallengeService {
    func getPrevChallenge(challengeType: ChallengeType, currentStep: Int) throws -> ChallengeObject? {
        
        // Check Current Challenge
        if currentStep <= 1 {
            return nil
            
        // Search Privous Challenge
        } else if let prevChallenge = challengeArray.first(where: { $0.chlg_type == challengeType && $0.chlg_step == currentStep - 1 }) {
            return prevChallenge
            
        //Exception Handling: Failed to Search
        } else {
            throw ChallengeError.UnexpectedPrevChallengeSearchError
        }
    }
}

//===============================
// MARK: - Exception
//===============================
enum ChallengeError: LocalizedError {
    case UnexpectedGetError
    case UnexpectedChallengeArrayError
    case UnexpectedMyChallengeSearchError
    case UnexpectedPrevChallengeSearchError
    case UnexpectedStepUpdateError
    case MyChallengeLimitExceeded
    case NoMoreNextChallenge
    
    var errorDescription: String?{
        switch self {
        case .MyChallengeLimitExceeded:
            return "Service: MyChallenge Limit Exceeded"
        case .UnexpectedGetError:
            return "Service: There was an unexpected error while Get Challenge in 'ChallengeService'"
        case .UnexpectedChallengeArrayError:
            return "Service: There was an unexpected error while Get Challenge From Array in 'ChallengeService'"
        case .UnexpectedMyChallengeSearchError:
            return "Service: There was an unexpected error while Search MyChallenge in 'ChallengeService'"
        case .UnexpectedPrevChallengeSearchError:
            return "Service: There was an unexpected error while Search Prev Challenge in 'ChallengeService'"
        case .UnexpectedStepUpdateError:
            return "Service: There was an unexpected error while Update ChallengeStep in 'ChallengeService'"
        case .NoMoreNextChallenge:
            return "Service: There is no more Available Challenge"
        }
    }
}

//===============================
// MARK: - Enum
//===============================
enum functionType {
    case set
    case disable
    case reward
    case next
}


