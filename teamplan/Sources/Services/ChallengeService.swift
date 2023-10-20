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
    // CoreData
    let chlgCD = ChallengeServicesCoredata()
    // Total Challenge Data
    var challengeArray: [ChallengeObject] = []
    // Extract Data from CoreData
    func initChallenge() async {
        //TODO: Exception Handling
        self.challengeArray = await chlgCD.getChallengeCoredata()
    }
    
    // StatisticsCenter
    let statCenter = StatisticsCenter(identifier: "Working Progress")
    
    //===============================
    // MARK: - MyChallenge: Total Get
    //===============================
    //TODO: Exception Handling
    func getMyChallenge() -> [ChallengeCardResDTO] {
        // extract challenge, that 'chlg_selected' is true
        let myChallenges = challengeArray.filter { $0.chlg_selected }
        return myChallenges.map { ChallengeCardResDTO(chlgObject: $0) }
    }
    
    
    //===============================
    // MARK: - MyChallenge: Detail Get
    //===============================
    /*TODO: Exception Handling
    func getMyChallengeDetail(challengeID: Int) -> MyChallengeDetailResDTO {

        let myChallengeDetail = challengeArray.first { $0.chlg_id == challengeID }
        let myChallengeType = myChallengeDetail?.chlg_type ?? .unknownType
        let userProgress = statCenter.returnUserProgress(challengeType: myChallengeType)
        
        return MyChallengeDetailResDTO( chlgObject: myChallengeDetail!, userProgress: userProgress )
    }
     */
    
    
    //===============================
    // MARK: - MyChallenge: select/disable
    //===============================
    //TODO: Exception Handling
    // * need return type?
    func selecteMyChallenge(challengeID: Int, status: Bool) async {
        
        // update challenge status
        let result = chlgCD.selectMyChallenge(chlg_id: challengeID, status: status)
        
        // update 'challengeArray'
        if result == true {
            self.challengeArray = await chlgCD.getChallengeCoredata()
        } else {
            print("Failed to update MyChallenges")
        }
    }
    
    //===============================
    // MARK: - Challeng: Total Get
    //===============================
    //TODO: Exception Handling
    func getChallenge() -> [ChallengeCardResDTO] {
        return self.challengeArray.map { ChallengeCardResDTO(chlgObject: $0) }
    }
    
    //===============================
    // MARK: - Challeng: Detail Get
    //===============================
    //TODO: Exception Handling
    func getChallengeDetail(challengeID: Int) -> ChallengeDetailResDTO {
        
        let challenge = challengeArray.first { $0.chlg_id == challengeID }!
        let prevChallengeDesc = calcPreviousChallenge(challengeObject: challenge)
        
        return ChallengeDetailResDTO(chlgObject: challenge, prevChallenge: prevChallengeDesc)
    }
    
    // Extension
    func calcPreviousChallenge(challengeObject: ChallengeObject) -> String {
        
        let currentStep = challengeObject.chlg_step
        let challengeType = challengeObject.chlg_type
        let prevChallenges = challengeArray.first { challenge -> Bool in
            return (challenge.chlg_type == challengeType) && (challenge.chlg_step == currentStep - 1)
        }
        //TODO: Exception Handling
        return prevChallenges?.chlg_title ?? "Can't find Previous Challenge"
    }
    
    //===============================
    // MARK: - My Challeng: Set MyChallenge
    //===============================
    
    
    
}
