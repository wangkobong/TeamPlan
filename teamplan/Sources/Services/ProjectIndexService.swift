//
//  ProjectIndexService.swift
//  teamplan
//
//  Created by 주찬혁 on 1/2/24.
//  Copyright © 2024 team1os. All rights reserved.
//

import Foundation

final class ProjectIndexService{
    
    //===============================
    // MARK: - Parameter
    //===============================
    let projectCD = ProjectServicesCoredata()
    let statCD = StatisticsServicesCoredata()
   
    let userId: String
    let statCenter: StatisticsCenter
    let chlgManager = ChallengeManager()
    
    var statDTO = StatProjectDTO()
    
    //===============================
    // MARK: - Initialize
    //===============================
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
//===============================
extension ProjectIndexService{

    //--------------------
    // Set
    //--------------------
    func setProject(with inputData: ProjectSetDTO) throws {
        // Statistics Update
        statDTO.updateProjectRegist(to: statDTO.projectRegisted + 1)
        
        // Set New ProjectData to Coredata
        //try projectCD.setProject(from: inputData, at: statDTO.projectRegisted, by: userId)
        
        // Adjust Update
        try updateStatProjectRegist()
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
    // Update: DeadLine
    //--------------------
    func updateDeadLineWithWaterDrop(in projectId: Int, with drop: Int) throws -> Date {
        // Get Extra Project Information
        let target = try projectCD.getProject(from: projectId, and: userId)
        
        // Ready to Extend
        let extend = drop * conversionRate
        
        // Extend DeadLine
        guard let updatedDate = Calendar.current.date(byAdding: .day, value: extend, to: target.proj_deadline) else {
            throw ProjectIndexError.UnexpectedUpdateError
        }
        // Adjust Update
        try updateProjectDeadLine(with: projectId, to: updatedDate)

        return updatedDate
    }
    
    func updateDeadLineWithNewDate(in projectId: Int, with newDate: Date) throws -> Int {
        // Get Extra Project Information
        let target = try projectCD.getProject(from: projectId, and: userId)
        
        // Extend DeadLine
        let component = Calendar.current.dateComponents([.day], from: target.proj_deadline, to: newDate)
        guard let needDrop = component.day else {
            throw ProjectIndexError.UnexpectedUpdateError
        }
        // Adjust Update
        try updateProjectDeadLine(with: projectId, to: newDate)
        
        return needDrop * conversionRate
    }
    
    //--------------------
    // Delete
    //--------------------
    func deleteProject(with projectId: Int) throws {
        try projectCD.deleteProject(with: projectId, and: userId)
    }
}

//===============================
// MARK: Support Function
//===============================
extension ProjectIndexService{
    
    private func updateStatProjectRegist() throws {
        let updatedData = StatUpdateDTO(
            userId: userId,
            newProjectRegisted: statDTO.projectRegisted
        )
        try statCD.updateStatistics(with: updatedData)
    }
    
    private func updateProjectDeadLine(with projectId: Int, to newDate: Date) throws {
        let updated = ProjectUpdateDTO(userId: userId, projectId: projectId, newDeadLine: newDate)
        try projectCD.updateProject(to: updated)
        try updateStatExtend()
    }
    
    private func updateStatExtend() throws {
        statDTO.updateProjectExtend(to: statDTO.projectExtended + 1)
        let updatedData = StatUpdateDTO(
            userId: userId,
            newProjectExtended: statDTO.projectExtended
        )
        try statCD.updateStatistics(with: updatedData)
    }
}

//===============================
// MARK: - Exception
//===============================
enum ProjectIndexError: LocalizedError {
    case UnexpectedUpdateError
    
    var errorDescription: String?{
        switch self {
        case .UnexpectedUpdateError:
            return "Service: There was an unexpected error while Update DeadLine in 'ProjectIndexService'"
        }
    }
}
