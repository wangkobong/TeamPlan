//
//  HomeService.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/08/25.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation

final class HomeService {
    
    let userCD = UserServicesCoredata()
    let projectCD = ProjectServicesCoredata()
    let challengeCD = ChallengeServicesCoredata()
    let genDummy = GenerateDummy()
    
    var identifier: String
    init(identifer: String){
        self.identifier = identifer
    }
    
    //===============================
    // MARK: - get User
    //===============================
    /// * Return Type : UserDTO / UserHomeResDTO
    ///    * success : 'user_id' & 'user_name' return
    ///    * exception : filled error message in 'user_id' & 'user_name'
    func getUser(result: @escaping(Result<String, Error>) -> Void) {
        userCD.getUserCoredata(identifier: self.identifier) { cdResult in
            switch cdResult {
            case .success(let userInfo):
                return result(.success(userInfo.user_name))
            case .failure(let error):
                return result(.failure(error))
            }
        }
    }
    
    func getDummyUser() ->UserHomeResDTO{
        
        let dummyUser = genDummy.createDummyUser()
        
        return UserHomeResDTO(userObject: dummyUser)
    }
    
    //===============================
    // MARK: - get Project
    //===============================
    func getProject(result: @escaping(Result<[ProjectCardResDTO], Error>) -> Void) {
        
        // extract all project info
        projectCD.getProjectCoredata(identifier: self.identifier) { cdResult in
            switch cdResult {
            case .success(let reqProjects):
                
                // sorted by 'deadline'
                let sortedProjects = reqProjects.sorted { $0.proj_deadline > $1.proj_deadline }
                
                // convert to DTO
                let convertedProjects = sortedProjects.map{ ProjectCardResDTO(from: $0) }
                
                // return top3 project Info
                return result(.success(Array(convertedProjects.prefix(3))))
              
            // Exception Error: Projects fetch Failed
            case .failure(let error):
                return result(.failure(error))
            }
        }
    }
    
    
    func getTDummyProject() -> [ProjectCardResDTO]{
        
        // get DummyProject
        let dummyProjects = genDummy.createDummyProject()
        
        // sorted by 'deadline'
        let sortedProjects = dummyProjects.sorted{ $0.proj_deadline < $1.proj_deadline }
        
        let convertedProjects = sortedProjects.map{ ProjectCardResDTO(from: $0) }
        
        // return top3 project info
        return Array(convertedProjects.prefix(3))
    }
    
    //===============================
    // MARK: - get MyChallenge
    //===============================
    
    func getMyChallenge(result: @escaping(Result<[ChallengeCardResDTO], Error>) -> Void) {
        
        challengeCD.getMyChallengeCoredata(identifier: self.identifier) { cdResult in
            switch cdResult {
            
            case .success(let cardObjects):
                let cardList = cardObjects.map { ChallengeCardResDTO(chlgObject: $0) }
                return result(.success(cardList))
                
            // Exception Handling: Failed to Get MyChallenge
            case .failure(let error):
                return result(.failure(error))
            }
        }
    }
    
    func getDummyMyChallenge() -> [ChallengeCardResDTO]{
        let dummyMyChallenge = genDummy.createDummyMyChallenge()
        let dummyMyChallengeDTO = dummyMyChallenge.map{ ChallengeCardResDTO(chlgObject: $0) }
        
        return Array(dummyMyChallengeDTO)
    }
    
}


