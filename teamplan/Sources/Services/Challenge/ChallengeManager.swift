//
//  ChallengeManager.swift
//  teamplan
//
//  Created by 주찬혁 on 11/27/23.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation

//===============================
// MARK: - Global Parameter
//===============================
let challengeCount: Int = 36
let conversionRate: Int = 1

//===============================
// MARK: - Local Parameter
//===============================
final class ChallengeManager{
    let challengeCD = ChallengeServicesCoredata()
    let challengeFS = ChallengeServicesFirestore()
    
    var challengeArray: [ChallengeObject] = []
    
}
//===============================
// MARK: Main Function
//===============================
extension ChallengeManager{
    
    //--------------------
    // Get Array: FS
    //--------------------
    func getChallenges() async throws {
        challengeArray = try await challengeFS.getChallenges()
    }
    
    //--------------------
    // Get Object
    //--------------------
    func getChallenge() throws -> [ChallengeObject]{
        if challengeArray == [] {
            throw ChallengeErrorFS.InternalError
        } else {
            return challengeArray
        }
    }
    
    //--------------------
    // Set: CD
    //--------------------
    func setChallenge() throws {
        try challengeCD.setChallenges(with: challengeArray)
    }
    
    //--------------------
    // Delete: CD
    //--------------------
    func delChallenge(with userId: String) throws {
        try challengeCD.deleteChallenges(with: userId)
    }
    
    //--------------------
    // Config Object
    //--------------------
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
