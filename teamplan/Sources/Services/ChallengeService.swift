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
    // MARK: - Global Parameter
    //===============================
    let challengeCD = ChallengeServicesCoredata()
    let challengeLogCD = ChallengeLogServicesCoredata()
    let statisticsCD = StatisticsServicesCoredata()
    let statCenter = StatisticsCenter()
    
    var userId: String
    
    @Published var myChallenges: [MyChallengeDTO] = []
    @Published var statistics: StatisticsDTO?
    @Published var challengeArray: [ChallengeObject] = []
    //===============================
    // MARK: - Constructor
    //===============================
    init(_ id: String) {
        self.userId = id
    }
    
    func readyService() throws {
        do {
            self.statistics = StatisticsDTO(statObject: try statisticsCD.getStatistics(from: self.userId))
            try self.challengeArray = challengeCD.getChallenges()
            try self.getMyChallengesProcess()
        } catch let error {
            throw error
        }
    }
    
    //===============================
    // MARK: Get MyChallenges
    //===============================
    func getMyChallenges() throws -> [MyChallengeDTO] {
        return self.myChallenges
    }
    
    // ###### Core Function ######
    private func getMyChallengesProcess() throws {
        
        // Check Parameter
        guard let stat = self.statistics else {
            throw ChallengeError.UnexpectedStatError
        }
        
        // get MyChallenge from Total Challenge
        var myChallenges: [MyChallengeDTO] = []
        for idx in stat.stat_mychlg {
            // Get Challenge
            let myChallenge = try challengeCD.getChallenge(from: idx)
            // Get UserProgress related Challenge
            let userProgress = statCenter.userProgress(from: myChallenge.chlg_type, from: stat)
            // Struct MyChallenge
            myChallenges.append(MyChallengeDTO(chlgObject: myChallenge, userProgress: userProgress))
        }
        
        // Set only first three items
        self.myChallenges =  Array(myChallenges.prefix(3))
    }
    
    //===============================
    // MARK: Disable MyChallenge (Update)
    //===============================
    // Disable
    func disableMyChallenge(from challengeId: Int) throws {
        // Search & Update Challenge
        let updatedChallenge = ChallengeStatusDTO(target: challengeId, select: false, disableTime: Date())
        try challengeCD.updateChallenge(from: updatedChallenge)
        
        // Update Statistics : Remove MyChallenge
        try updateStatistics(challengeId, nil, nil)
        
        // Refresh MyChallenge
        try getMyChallengesProcess()
    }
    
    //===============================
    // MARK: Reward MyChallenge (Update)
    //===============================
    // Reward
    func rewardMyChallenge(from challengeId: Int) throws -> ChallengeRewardDTO {
        let updatedDate = Date()
        
        // Update Reward Challenge
        let targetChallenge = try rewardChallengeUpdate(challengeId, updatedDate)
        
        // Update Next Challenge
        let nextChallenge = try nextChallengeUpdate(challengeId)
        
        // Update Statistics
        try updateStatistics(challengeId, nextChallenge.chlg_type, targetChallenge.chlg_reward)
        
        // Update ChallengeLog
        try challengeLogCD.updateLog(with: self.userId, updatedLog: [challengeId : updatedDate], updatedAt: updatedDate)
        
        // Return Next Challenge
        return ChallengeRewardDTO(from: targetChallenge, to: nextChallenge)
    }
}

//===============================
// MARK: - Support Func: Statistics
//===============================
extension ChallengeService {
    
    // Update Statistics (Set MyChallenge)
    private func updateStatistics(_ id: Int) throws {
        // Check Parameter
        guard var stat = self.statistics else {
            throw ChallengeError.UnexpectedStatError
        }
        // Add Challenge to MyChallenge & Update Statistics
        stat.stat_mychlg.append(id)
        try statisticsCD.updateStatistics(to: stat)
        
        // Refresh Statistics
        self.statistics = stat
    }
    
    // Update Statistics (Disable or Reward MyChallenge)
    private func updateStatistics(_ id: Int, _ type: ChallengeType?, _ reward: Int?) throws {
        // Check Parameter
        guard var stat = self.statistics else {
            throw ChallengeError.UnexpectedStatError
        }
        // reward MyChallenge Active Only
        if let type = type, let reward = reward {
            // Update ChallengeStep
            stat = try updateChallengeStep(stat, type)
            // Update DropCount
            stat.updateWaterDrop(to: stat.stat_drop + reward)
        }
        // Search Target Challenge at MyChallenges
        guard let idx = stat.stat_mychlg.firstIndex(of: id) else {
            throw ChallengeError.UnexpectedMyChallengeSearchError
        }
        // Remove Challenge from MyChallenges & Update
        stat.stat_mychlg.remove(at: idx)
        try statisticsCD.updateStatistics(to: stat)
            
        // Refresh Statistics
        self.statistics = stat
    }
    
    // Update Statistics: Challenge Step
    private func updateChallengeStep(_ stat: StatisticsDTO, _ type: ChallengeType) throws -> StatisticsDTO {
        var updatedStat = stat
        
        // Check if the key exists and update its value
        if let currentVal = updatedStat.stat_chlg_step[type.rawValue] {
            updatedStat.stat_chlg_step[type.rawValue] = currentVal + 1
        } else {
            // If the key doesn't exist, handle the error
            throw ChallengeError.UnexpectedStepUpdateError
        }
        return updatedStat
    }
}

//===============================
// MARK: - Support Func: Challenge
//===============================
extension ChallengeService {
    // Update Challenge : Reward Target
    private func rewardChallengeUpdate(_ id: Int, _ date: Date) throws -> ChallengeObject {
        let updatedChallenge = ChallengeStatusDTO(target: id, when: date)
        try challengeCD.updateChallenge(from: updatedChallenge)
        return try challengeCD.getChallenge(from: id)
    }

    // Update Challenge : Next Target
    private func nextChallengeUpdate(_ id: Int) throws -> ChallengeObject {
        // Search Next Challenge
        guard let currentChallenge = self.challengeArray.first(where: { $0.chlg_id == id }),
              let nextChallenge = try getNextChallenge(challengeType: currentChallenge.chlg_type, currentStep: currentChallenge.chlg_step)
        else {
            throw ChallengeError.UnexpectedNextChallengeSearchError
        }

        // Struct DTO & Update
        let updatedChallenge = ChallengeStatusDTO(target: nextChallenge.chlg_id, status: true)
        try challengeCD.updateChallenge(from: updatedChallenge)
        return nextChallenge
    }
    
    // Get Challenge : Next Target
    private func getNextChallenge(challengeType: ChallengeType, currentStep: Int) throws -> ChallengeObject? {
        // Check Parameter
        let array = self.challengeArray
        return array.first { $0.chlg_type == challengeType && $0.chlg_step == currentStep + 1 }
    }
}

extension ChallengeService {
    //===============================
    // MARK: Get Challenges
    //===============================
    func getChallenges() throws -> [ChallengeDTO] {
        // Check Parameter
        let array = self.challengeArray
        return array.map { ChallengeDTO(from: $0) }
    }
     
    //===============================
    // MARK: Get Challenge
    //===============================
    func getChallenge(from id: Int) throws -> ChallengeDTO {
        // Check Parameter
        let array = self.challengeArray
        // Search Challenge
        guard let challenge = array.first(where: { $0.chlg_id == id }) else {
            throw ChallengeError.UnexpectedGetError
        }
        // Search Prev Challenge
        guard let prevChallenge = try getPrevChallenge(challengeType: challenge.chlg_type, currentStep: challenge.chlg_step) else {
            return ChallengeDTO(from: challenge)
        }
        return ChallengeDTO(from: challenge, prev: prevChallenge)
    }
    
    //===============================
    // MARK: Update Challenge
    //===============================
    func setMyChallenge(from challengeId: Int) throws {
        // Search & Update Challenge
        let updatedChallenge = ChallengeStatusDTO(target: challengeId, select: true, selectTime: Date())
        try challengeCD.updateChallenge(from: updatedChallenge)
        
        // Update Statistics : Add MyChallenge
        try updateStatistics(challengeId)
        
        // Refresh MyChallenge
        try getMyChallengesProcess()
    }
}

//===============================
// MARK: - Support Func
//===============================
extension ChallengeService {
    func getPrevChallenge(challengeType: ChallengeType, currentStep: Int) throws -> ChallengeObject? {
        // Check Parameter
        let array = self.challengeArray
        // Check Current Challenge
        if currentStep <= 1 {
            return nil
            // Search Privous Challenge
        } else if let prevChallenge = array.first(where: { $0.chlg_type == challengeType && $0.chlg_step == currentStep - 1 }) {
            return prevChallenge
        } else {
            //Exception Handling: Failed to Search
            throw ChallengeError.UnexpectedPrevChallengeSearchError
        }
    }
}

//===============================
// MARK: - Exception
//===============================
enum ChallengeError: LocalizedError {
    case UnexpectedGetError
    case UnexpectedStatError
    case UnexpectedChallengeArrayError
    case UnexpectedMyChallengeSearchError
    case UnexpectedNextChallengeSearchError
    case UnexpectedPrevChallengeSearchError
    case UnexpectedStepUpdateError
    
    var errorDescription: String?{
        switch self {
        case .UnexpectedGetError:
            return "Service: There was an unexpected error while Get Challenge in 'ChallengeService'"
        case .UnexpectedStatError:
            return "Service: There was an unexpected error while Check Statistics Data in 'ChallengeService'"
        case .UnexpectedChallengeArrayError:
            return "Service: There was an unexpected error while Check Challenge Array in 'ChallengeService'"
        case .UnexpectedMyChallengeSearchError:
            return "Service: There was an unexpected error while Search MyChallenge in 'ChallengeService'"
        case .UnexpectedNextChallengeSearchError:
            return "Service: There was an unexpected error while Search Next Challenge in 'ChallengeService'"
        case .UnexpectedPrevChallengeSearchError:
            return "Service: There was an unexpected error while Search Prev Challenge in 'ChallengeService'"
        case .UnexpectedStepUpdateError:
            return "Service: There was an unexpected error while Update ChallengeStep in 'ChallengeService'"
        }
    }
}


