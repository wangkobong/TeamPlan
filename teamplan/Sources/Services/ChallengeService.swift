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
    // StatisticsCenter
    let statCenter: StatisticsCenter
    // Total Challenge Data
    var challengeArray: [ChallengeObject] = []
    // Identifier
    var identifier: String
    
    @Published var myChallenges: [ChallengeCardResDTO] = []
    
    //===============================
    // MARK: - Constructor
    //===============================
    init(identifier: String){
        self.identifier = identifier
        self.statCenter = StatisticsCenter(identifier: identifier)
        
        self.getMyChallenge { result in
            switch result {
            case .success(let challenges):
                self.myChallenges = challenges
            case .failure(_):
                self.myChallenges = []
            }
        }
    }
    
    // Pre Load Challenge Data
    func initChallenge(result: @escaping(Result<Bool, Error>) -> Void) {
        chlgCD.getChallenges { cdResult in
            switch cdResult {
            case .success(let reqChlg):
                self.challengeArray = reqChlg
                return result(.success(true))
            case.failure(let error):
                return result(.failure(error))
            }
        }
    }

    //===============================
    // MARK: Get - MyChallenges
    //===============================
    //TODO: Exception Handling
    func getMyChallenge(result: @escaping(Result<[ChallengeCardResDTO], Error>) -> Void) {
        
        // extract challenge, that 'chlg_selected' is true
        let myChallenges = challengeArray.filter { $0.chlg_selected }.map { ChallengeCardResDTO(chlgObject: $0) }
        
        // return myChallengeCard Array
        return result(myChallenges.isEmpty ? .failure(ChallengeError.NoMyChallenge) : .success(myChallenges))
    }
    
    //===============================
    // MARK: Get - MyChallenge Detail
    //===============================
    //TODO: Exception Handling
    func getMyChallengeDetail(challengeId: Int,
                              result: @escaping(Result<MyChallengeDetailResDTO, Error>) -> Void) {
        
        // extract challenge, that 'chlg_selected' is true
        guard let challenge = challengeArray.first(where: { $0.chlg_id == challengeId }) else {
            return result(.failure(ChallengeError.InvalidChallengeId))
        }
        // get userPorgress
        statCenter.returnUserProgress(challengeType: challenge.chlg_type) { centerRes in
            switch centerRes {
            case .success(let progress):
                
                // struct challengeDetail
                let detail = MyChallengeDetailResDTO(chlgObject: challenge, userProgress: progress)
                return result(.success(detail))
            
            // Exception Handling: Invalid ChallengeType
            case .failure(let error):
                return result(.failure(error))
            }
            
        }
    }
    
    //===============================
    // MARK: Select - MyChallenges
    //===============================
    //TODO: Exception Handling
    // * need return type?
    func selecteMyChallenge(challengeID: Int, status: Bool,
                            result: @escaping(Result<Bool, Error>) -> Void) {
        
        // get ChallengeData
        guard let reqChallenge = findChallengeByID(in: self.challengeArray, challengeId: challengeID) else {
            return result(.failure(ChallengeError.InvalidChallengeId))
        }
        
        // Update ChallengeData
        let updatedChallenge = ChallengeStatusReqDTO(chlgObject: reqChallenge, myChlg: status)
        chlgCD.updateChallengeStatus(updatedChallenge: updatedChallenge) { cdResult in
            
            switch cdResult {
            case .success:
                
                // Adjust updated 'challengeArray'
                self.initChallenge() { updateRes in
                    
                    switch updateRes {
                    case .success:
                        return result(.success(true))
                    
                    // Exception Handling : Failed to get ChallengeList
                    case .failure(let error):
                        return result(.failure(error))
                    }
                }
            // Exception Handling : 'Invalid identifier' or 'Invalid challengeID
            case .failure(let error):
                return result(.failure(error))
            }
        }
    }

    
    //===============================
    // MARK: Get - Challenges
    //===============================
    func getChallenge(result: @escaping(Result<[ChallengeCardResDTO], Error>) -> Void) {
        
        // extract every challenges
        let challenges = challengeArray.map { ChallengeCardResDTO(chlgObject: $0) }
        
        // return totalChallengeCard Array
        result(challenges.isEmpty ? .failure(ChallengeError.InternalError) : .success(challenges))
    }
    
    //===============================
    // MARK: Get - Challenge Detail
    //===============================
    func getChallengeDetail(challengeId: Int,
                            result: @escaping(Result<ChallengeDetailResDTO, Error>) -> Void) {
        
        // extract challenge, that 'chlg_selected' is true
        guard let challenge = challengeArray.first(where: { $0.chlg_id == challengeId }) else {
            return result(.failure(ChallengeError.InvalidChallengeId))
        }
        // get Privous Challenge Description
        getPrevChallengeDesc(challengeType: challenge.chlg_type, currentStep: challenge.chlg_step) { descRes in
            switch descRes {
            
            case .success(let desc):
                let detail = ChallengeDetailResDTO(chlgObject: challenge, prevChallenge: desc)
                return result(.success(detail))
            
                //Exception Handling: Failed to Search Previous Challenge
            case .failure(let error):
                return result(.failure(error))
            }
        }
    }
    
    // Extension
    func getPrevChallengeDesc(challengeType: ChallengeType, currentStep: Int, result: @escaping(Result<String, Error>) -> Void) {
        // Search Privous Challenge
        if let prevChallenge = challengeArray.first(where: { $0.chlg_type == challengeType && $0.chlg_step == currentStep - 1 }) {
            // return Previous Challenge Description
            result(.success(prevChallenge.chlg_desc))
        } else {
            //Exception Handling: Failed to Search
            result(.failure(ChallengeError.PreviousChallengeSearchFailed))
        }
    }
}

//===============================
// MARK: - Support Function
//===============================
extension ChallengeService {
    func findChallengeByID(in challenges: [ChallengeObject], challengeId: Int) -> ChallengeObject? {
        return challenges.first { $0.chlg_user_id == identifier }
    }
}

//===============================
// MARK: - Exception
//===============================
enum ChallengeError: LocalizedError {
    case NoMyChallenge
    case ChallengeIdGetFailed
    case IdentifierGetFailed
    case InvalidChallengeId
    case InvalidType
    case InternalError
    case PreviousChallengeSearchFailed
    
    var errorDescription: String?{
        switch self {
        case .NoMyChallenge:
            return "No Selected Challenge for MyChallenge"
        case .ChallengeIdGetFailed:
            return "Failed to Get Challenge by ChallengeID"
        case .IdentifierGetFailed:
            return "Failed to Get Challenge by identifier"
        case .InvalidChallengeId:
            return "Invalid ChallengeID"
        case .InvalidType:
            return "Invalid ChallengeType"
        case .InternalError:
            return "Failed to get Challenge by InternalError"
        case .PreviousChallengeSearchFailed:
            return "Failed to Search Previous Challenge"
        }
    }
}


