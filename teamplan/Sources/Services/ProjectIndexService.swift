//
//  ProjectIndexService.swift
//  teamplan
//
//  Created by 주찬혁 on 1/2/24.
//  Copyright © 2024 team1os. All rights reserved.
//

import Foundation

final class ProjectIndexService{
    
    //--------------------
    // Parameter
    //--------------------
    let projectCD = ProjectServicesCoredata()
    let projectLogCD = ProjectLogServicesCoredata()
    let statCD = StatisticsServicesCoredata()
   
    let userId: String
    let statCenter: StatisticsCenter
    let chlgManager = ChallengeManager()
    
    var statDTO = StatProjectDTO()
    
    //--------------------
    // Initialize
    //--------------------
    init(with userId: String){
        self.userId = userId
        self.statCenter = StatisticsCenter(with: userId)
    }
    
    func readyService() throws {
        self.statDTO = try statCD.getStatisticsForDTO(with: userId, type: .project) as! StatProjectDTO
    }
}

//===============================
// MARK: Main Function
// * CRUD
//===============================
extension ProjectIndexService{

    //--------------------
    // Set
    //--------------------
    func setProject(with inputData: ProjectSetDTO) throws {
        
        // Add New Project
        let newProjectRegist = try setCoreFunction(with: inputData)
        // update Statistics
        try setCleanupFunction(with: newProjectRegist)
    }
    
    //--------------------
    // Get
    //--------------------
    // User Statistics
    func getStatistics() throws -> userStatProjectDTO {
        // Ready for struct DTO
        let projectCount = try getProjects().count
        
        // Struct DTO & Return
        return userStatProjectDTO(with: statDTO, and: projectCount)
    }
    
    // Project Index
    func getProjects() throws -> [ProjectCardDTO] {
        // Get ProjectCard Data
        let array = try projectCD.getProjectCards(by: userId)
        
        // Sort & Return Data
        let sortedArray = array.sorted{ $0.startedAt > $1.startedAt }
        return sortedArray
    }
    
    //--------------------
    // Update
    //--------------------
    func updateProjectDeadline(with projectid: Int, newDeadline: Date, needDrop: Int) throws {
        // Update Statitstics
        try updateCleanupFunction(with: needDrop)
        // Apply Update
        try updateCoreFunction(with: newDeadline, and: needDrop, id: projectid)
    }
    
    //--------------------
    // Delete
    //--------------------
    func deleteProject(with projectId: Int) throws {
        try projectCD.deleteProject(with: projectId, and: userId)
    }
}

//===============================
// MARK: Main Function
// * Calculation
//===============================
extension ProjectIndexService{
    
    //--------------------
    // Date
    //--------------------
    private func calcDate(with projectId: Int, and drop: Int) throws -> Date {
        // Drop Limit Check
        if drop > statDTO.waterDrop {
            throw ProjectIndexError.ExceedLimitWaterDrop
        }
        // Ready Parameter
        let target = try projectCD.getProject(from: projectId, and: userId)
        let extend = drop * conversionRate
        
        // Calculation DeadLine
        guard let updatedDate = Calendar.current.date(byAdding: .day, value: extend, to: target.proj_deadline) else {
            throw ProjectIndexError.UnexpectedUpdateError
        }
        return updatedDate
    }
    
    //--------------------
    // WaterDrop
    //--------------------
    private func calcDrop(with projectId: Int, and newDate: Date) throws -> Int {
        // Get Extra Project Information
        let target = try projectCD.getProject(from: projectId, and: userId)
        
        // Calculation WaterDrop
        let component = Calendar.current.dateComponents([.day], from: target.proj_deadline, to: newDate)
        guard let needDrop = component.day else {
            throw ProjectIndexError.UnexpectedUpdateError
        }
        // Drop Limit Check
        if needDrop > statDTO.waterDrop {
            throw ProjectIndexError.ExceedLimitWaterDrop
        }
        
        return needDrop
    }
}

//===============================
// MARK: Support Function
// * Components
//===============================
extension ProjectIndexService{
    
    // Set: Core
    private func setCoreFunction(with dto: ProjectSetDTO) throws -> Int{
        // Ready Parameter
        let setDate = Date()
        let newId = statDTO.projectRegisted + 1
        let newLog = ProjectLog(with: dto, id: newId, by: userId, at: setDate)
        // Set Entity
        try projectCD.setProject(with: dto, id: newId, by: userId, at: setDate)
        try projectLogCD.setLog(with: newLog)
        // Return ProjectRegist
        return newId
    }
    // Set: Cleanup
    private func setCleanupFunction(with newProjectRegist: Int) throws {
        statDTO.updateProjectRegist(to: newProjectRegist)
        try updateStatProjectRegist()
    }

    // Update: Core
    private func updateCoreFunction(with updatedDeadline: Date, and drop: Int, id projectId: Int) throws {
        // Ready Parameter
        let updatedDate = Date()
        let updatedProject = ProjectUpdateDTO(
            userId: userId, projectId: projectId, newDeadLine: updatedDeadline)
        let updatedStat = StatUpdateDTO(
            userId: userId, newDrop: statDTO.waterDrop, newProjectExtended: statDTO.projectExtended)
        let updatedExtendInfo = [drop : updatedDate]
        let updatedLog = ProjectLogUpdateDTO(
            userId: userId, projectId: projectId, extendInfo: updatedExtendInfo, deadline: updatedDeadline)
        
        // Update: Project
        try projectCD.updateProject(to: updatedProject)
        // Update: Statistics
        try statCD.updateStatistics(with: updatedStat)
        // Update: ProjectLog
        try projectLogCD.updateLog(with: updatedLog)
    }
    // Update: CleanUp
    private func updateCleanupFunction(with drop: Int) throws {
        // Update Statistics
        statDTO.updateProjectExtend(to: statDTO.projectExtended + 1)
        statDTO.updateWaterDrop(to: statDTO.waterDrop - drop)
    }
}


//===============================
// MARK: Support Function
// * Etc
//===============================
extension ProjectIndexService{
    
    // Update: Project Registed
    private func updateStatProjectRegist() throws {
        let updatedData = StatUpdateDTO(
            userId: userId,
            newProjectRegisted: statDTO.projectRegisted
        )
        try statCD.updateStatistics(with: updatedData)
    }
}

//===============================
// MARK: - Exception
//===============================
enum ProjectIndexError: LocalizedError {
    case UnexpectedUpdateError
    case ExceedLimitWaterDrop
    
    var errorDescription: String?{
        switch self {
        case .UnexpectedUpdateError:
            return "Service: There was an unexpected error while Update DeadLine in 'ProjectIndexService'"
        case .ExceedLimitWaterDrop:
            return "Service: There was WaterDrop Exceeded Limit while Update Deadline in 'ProjectIndexService'"
        }
    }
}
