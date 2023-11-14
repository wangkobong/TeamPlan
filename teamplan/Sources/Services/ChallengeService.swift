//
//  ChallengeService.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/10/10.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation

final class ChallengeService{
    
    //===============================
    // MARK: - Global Parameter
    //===============================
    let challengeCD = ChallengeServicesCoredata()
    let challengeLogCD = ChallengeLogServicesCoredata()
    let statisticsCD = StatisticsServicesCoredata()
    let statCenter = StatisticsCenter()
    
    var userId: String
    var statistics: StatisticsDTO?
    var challengeArray: [ChallengeObject]?
    
    @Published var myChallenges: [MyChallengeDTO]?
    
    //===============================
    // MARK: - Constructor
    //===============================
    init(_ id: String){
        self.userId = id
    }
    
    // Preload Statistics for 'ChallengeView' Constructor
    func loadStatistics() throws {
        self.statistics = StatisticsDTO(statObject: try statisticsCD.getStatistics(from: self.userId))
    }
    
    // Preload Challenge Data
    func loadChallenges() throws {
        try self.challengeArray = challengeCD.getChallenges()
    }
    
    // Preload MyChallenge Data
    func loadMyChallenges() throws {
        try self.getMychallengesProcess()
    }
    
    //===============================
    // MARK: Set MyChallenges
    //===============================
    func setMyChallenge(from challengeId: Int) async throws {
        // Search & Update Challenge
        let updatedChallenge = ChallengeStatusDTO(target: challengeId, select: true, selectTime: Date())
        try await challengeCD.updateChallenge(from: updatedChallenge)
        
        // Update Statistics : Add MyChallenge
        try await updateStatistics(challengeId)
        
        // Refresh MyChallenge
        try getMychallengesProcess()
    }
    
    //===============================
    // MARK: Get MyChallenges
    //===============================
    func getMyChallenges() throws -> [MyChallengeDTO] {
        return self.myChallenges ?? []
    }
    
    // ###### Core Function ######
    private func getMychallengesProcess() throws {
        
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
    func disableMyChallenge(from challengeId: Int) async throws {
        // Search & Update Challenge
        let updatedChallenge = ChallengeStatusDTO(target: challengeId, select: false, disableTime: Date())
        try await challengeCD.updateChallenge(from: updatedChallenge)
        
        // Update Statistics : Remove MyChallenge
        try await updateStatistics(challengeId, nil)
        
        // Refresh MyChallenge
        try getMychallengesProcess()
    }
    
    //===============================
    // MARK: Reward MyChallenge (Update)
    //===============================
    // Reward
    func rewardMyChallenge(from challengeId: Int) async throws -> ChallengeRewardDTO {
        let updatedDate = Date()
        
        // Update Reward Challenge
        try await rewardChallengeUpdate(challengeId, updatedDate)
        
        // Update Next Challenge
        let nextChallenge = try await nextChallengeUpdate(challengeId)
        
        // Update Statistics
        try await updateStatistics(challengeId, nextChallenge.chlg_type)
        
        // Update ChallengeLog
        try await challengeLogCD.updateLog(to: self.userId, what: [challengeId : updatedDate], when: updatedDate)
        
        // Return Next Challenge
        return ChallengeRewardDTO(from: nextChallenge)
    }
}

//===============================
// MARK: - Support Func: Statistics
//===============================
extension ChallengeService {
    
    // Update Statistics (Add)
    private func updateStatistics(_ id: Int) async throws {
        // Check Parameter
        guard var stat = self.statistics else {
            throw ChallengeError.UnexpectedStatError
        }
        // Add Challenge to MyChallenge & Update Statistics
        stat.stat_mychlg.append(id)
        try await statisticsCD.updateStatistics(from: self.userId, to: stat)
        
        // Refresh Statistics
        self.statistics = stat
    }
    
    // Update Statistics (Remove)
    private func updateStatistics(_ id: Int, _ type: ChallengeType?) async throws {
        // Check Parameter
        guard var stat = self.statistics else {
            throw ChallengeError.UnexpectedStatError
        }
        // reward MyChallenge Active Only
        if let type = type {
            try updateChallengeStep(stat, type)
        }
        // Search Target Challenge at MyChallenges
        guard let idx = stat.stat_mychlg.firstIndex(of: id) else {
            throw ChallengeError.UnexpectedMyChallengeSearchError
        }
        // Remove Challenge from MyChallenges & Update
        stat.stat_mychlg.remove(at: idx)
        try await statisticsCD.updateStatistics(from: self.userId, to: stat)
            
        // Refresh Statistics
        self.statistics = stat
    }
    
    // Update Statistics: Challenge Step
    private func updateChallengeStep(_ stat: StatisticsDTO, _ type: ChallengeType) throws {
        // Search ChallengeStep Data
        guard let idx = stat.stat_chlg_step.firstIndex(where: { $0.keys.contains(type.rawValue) } ),
              let currentVal = stat.stat_chlg_step[idx][type.rawValue] else {
            throw ChallengeError.UnexpectedStepUpdateError
        }
        // Update ChallengeStep Data
        var updatedstat = stat
        updatedstat.stat_chlg_step[idx][type.rawValue] = currentVal + 1
        self.statistics = updatedstat
    }
}

//===============================
// MARK: - Support Func: Challenge
//===============================
extension ChallengeService {
    // Update Challenge : Reward Target
    private func rewardChallengeUpdate(_ id: Int, _ date: Date) async throws {
        let updatedChallenge = ChallengeStatusDTO(target: id, when: date)
        try await challengeCD.updateChallenge(from: updatedChallenge)
    }

    // Update Challenge : Next Target
    private func nextChallengeUpdate(_ id: Int) async throws -> ChallengeObject {
        // Search Next Challenge
        guard let currentChallenge = self.challengeArray?.first(where: { $0.chlg_id == id }),
              let nextChallenge = try getNextChallenge(challengeType: currentChallenge.chlg_type, currentStep: currentChallenge.chlg_step)
        else {
            throw ChallengeError.UnexpectedNextChallengeSearchError
        }

        // Struct DTO & Update
        let updatedChallenge = ChallengeStatusDTO(target: nextChallenge.chlg_id, status: true)
        try await challengeCD.updateChallenge(from: updatedChallenge)
        return nextChallenge
    }
    
    // Get Challenge : Next Target
    private func getNextChallenge(challengeType: ChallengeType, currentStep: Int) throws -> ChallengeObject? {
        // Check Parameter
        guard let array = self.challengeArray else {
            throw ChallengeError.UnexpectedChallengeArrayError
        }
        return array.first { $0.chlg_type == challengeType && $0.chlg_step == currentStep + 1 }
    }
}

//===============================
// MARK: Get Challenge
//===============================
extension ChallengeService {
    func getChallenge(from id: Int) throws -> ChallengeDTO {
        // Check Parameter
        guard let array = self.challengeArray else {
            throw ChallengeError.UnexpectedChallengeArrayError
        }
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
}

//===============================
// MARK: - Support Func
//===============================
extension ChallengeService {
    func getPrevChallenge(challengeType: ChallengeType, currentStep: Int) throws -> ChallengeObject? {
        // Check Parameter
        guard let array = self.challengeArray else {
            throw ChallengeError.UnexpectedChallengeArrayError
        }
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


