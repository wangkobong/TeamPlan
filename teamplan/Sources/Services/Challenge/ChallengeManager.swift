//
//  ChallengeManager.swift
//  teamplan
//
//  Created by 주찬혁 on 11/27/23.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation

let challengeCount: Int = 36

final class ChallengeManager{
    
    //===============================
    // MARK: - Global Parameter
    //===============================
    
    let challengeCD = ChallengeServicesCoredata()
    let challengeFS = ChallengeServicesFirestore()
    
    var challengeArray: [ChallengeObject] = []
    
    //===============================
    // MARK: - Fetch Challenges
    //===============================
    func fetchChallenge() async throws {
        challengeArray = try await challengeFS.getChallenges()
    }
    
    func getChallenge() throws -> [ChallengeObject]{
        if challengeArray == [] {
            throw ChallengeErrorFS.InternalError
        } else {
            return challengeArray
        }
    }
    
    func setChallenge() throws {
        try challengeCD.setChallenges(with: challengeArray)
    }
    
    //===============================
    // MARK: - Delete Challenges
    //===============================
    func delChallenge(with userId: String) throws {
        try challengeCD.deleteChallenges(with: userId)
    }
    
    //===============================
    // MARK: - Challenges Configure
    //===============================
    func configChallenge(with userId: String) {
        
        // Unlock Step1 Challenge & assign UserId
        for idx in challengeArray.indices {
            if challengeArray[idx].chlg_step == 1 {
                challengeArray[idx].updateLock(with: false)
            }
            challengeArray[idx].addUserId(with: userId)
        }
    }
}
