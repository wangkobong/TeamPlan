//
//  HomeService.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/08/25.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation

final class HomeService {
    
    let projectCD = ProjectServicesCoredata()
    let userCD = UserServicesCoredata()
    let challengeCD = ChallengeServicesCoredata()
    
    let genDummy = GenerateDummy()
    
    //===============================
    // MARK: - get User
    //===============================
    /// * Return Type : UserDTO / UserHomeResDTO
    ///    * success : 'user_id' & 'user_name' return
    ///    * exception : filled error message in 'user_id' & 'user_name'
    func getUser(identifier: String) async -> UserHomeResDTO {
        
        let requestUser = await userCD.getUserCoredata(identifier: identifier)
        
        return UserHomeResDTO(userObject: requestUser)
    }
    
    func getDummyUser() ->UserHomeResDTO{
        
        let dummyUser = genDummy.createDummyUser()
        
        return UserHomeResDTO(userObject: dummyUser)
    }
    
    //===============================
    // MARK: - get Project
    //===============================
    // TODO: Add logic - No ProjectData case
    func getProject() async -> [ ProjectCardResDTO ]{
        
        // extract all project info
        let fetchProjects = await projectCD.getProjectCoredata()
        
        // sorted by 'deadline'
        let sortedProjects = fetchProjects.sorted{ $0.proj_deadline > $1.proj_deadline }
        
        // convert to DTO
        let convertedProjects = sortedProjects.map{ ProjectCardResDTO(from: $0) }
        
        // return top3 project Info
        return Array(convertedProjects.prefix(3))
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
    
    func getMyChallenge() async -> [ChallengeCardResDTO]{
        
        let myChallenge = await challengeCD.getMyChallengeCoredata()
        let myChallengeDTO = myChallenge.map{ ChallengeCardResDTO(chlgObject: $0) }
        
        return Array(myChallengeDTO)
    }
    
    func getDummyMyChallenge() -> [ChallengeCardResDTO]{
        let dummyMyChallenge = genDummy.createDummyMyChallenge()
        let dummyMyChallengeDTO = dummyMyChallenge.map{ ChallengeCardResDTO(chlgObject: $0) }
        
        return Array(dummyMyChallengeDTO)
    }
    
}


