//
//  HomeService.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/08/25.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation

final class HomeService{
    
    let cd = ProjectServicesCoredata(storeType: .binary)
    
    //===============================
    // MARK: - get User
    //===============================
    
    
    
    
    
    //===============================
    // MARK: - get Project
    //===============================
    func getProject() async -> [ProjectHomeLocalResDTO]{
        
        // extract all project info
        let fetchProjects = await cd.getProjectCoredata()
        
        // sorted by 'deadline'
        let sortedProjects = fetchProjects.sorted{ $0.proj_deadline > $1.proj_deadline }
        
        // return top3 project Info
        return Array(sortedProjects.prefix(3))
    }
    
    
    func getTestProject() -> [ProjectHomeLocalResDTO]{
        
        // get DummyProject
        let dummyProjects = cd.createDummyProject()
        
        // sorted by 'deadline'
        let sortedProjects = dummyProjects.sorted{ $0.proj_deadline < $1.proj_deadline }
        
        let convertedProjects = sortedProjects.map{ProjectHomeLocalResDTO(from: $0)}
        
        // return top3 project info
        return Array(convertedProjects.prefix(3))
    }
    
    //===============================
    // MARK: - get Challenge
    //===============================
}


