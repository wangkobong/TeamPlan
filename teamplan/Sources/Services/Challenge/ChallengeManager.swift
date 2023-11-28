//
//  ChallengeManager.swift
//  teamplan
//
//  Created by 주찬혁 on 11/27/23.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation

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
    func setChallenge() async throws {
        
        // Get Challenges from firestore
        self.challengeArray = try await challengeFS.getChallenges()
        
        // Reset Unlock Status
        for idx in self.challengeArray.indices {
            if self.challengeArray[idx].chlg_step == 1{
                self.challengeArray[idx].resetUnlock()
            }
        }
        // Set Challenges to Coredata
        try challengeCD.setChallenges(reqChallenges: self.challengeArray)
    }
    //===============================
    // MARK: - Delete Challenges
    //===============================
    func delChallenge() throws {
        try challengeCD.deleteChallenges()
    }
}
