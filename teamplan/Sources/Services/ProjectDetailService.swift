//
//  ProjectDetailService.swift
//  teamplan
//
//  Created by 주찬혁 on 1/3/24.
//  Copyright © 2024 team1os. All rights reserved.
//

import Foundation

final class ProjectDetailService{
    
    //===============================
    // MARK: - Parameter
    //===============================
    let projectCD = ProjectServicesCoredata()
    let projectLogCD = ProjectLogServicesCoredata()
    let todoCD = TodoServiceCoredata()
    let statCD = StatisticsServicesCoredata()
    let util = Utilities()
    
    //--------------------
    // Service Use Only
    //--------------------
    let projectId: Int
    let userId: String
    var statDTO: StatTodoDTO
    var todoList: [TodoObject] = []
    
    //--------------------
    // For ViewModel
    //--------------------
    @Published var projectDetail: ProjectDetailDTO
    
    //===============================
    // MARK: - Initialize
    //===============================
    init(userId: String, projectId: Int){
        self.userId = userId
        self.projectId = projectId
        self.projectDetail = ProjectDetailDTO()
        self.statDTO = StatTodoDTO()
    }
    
    //TODO: Struct Daily Reset Todo Logic
    func readyService() throws {
        // Ready Components
        let object = try projectCD.getProject(from: projectId, and: userId)
        let period = try util.calculateDatePeroid(with: object.proj_started_at, and: object.proj_deadline)
        statDTO = try statCD.getStatisticsForDTO(with: userId, type: .todo) as! StatTodoDTO
        
        // Ready ProjectDetail
        projectDetail = ProjectDetailDTO(
            with: object,
            period: period,
            limit: statDTO.todoLimit
        )
        // Reset todoList
        todoList = try todoCD.getTodoList(
            with: TodoRequestDTO(
                projectId: object.proj_id,
                userId: object.proj_user_id
            )
        )
    }
}

//===============================
// MARK: Main Function
//===============================
extension ProjectDetailService{
    
    //--------------------
    // Set
    //--------------------
    func setTodo(with dto: TodoSetDTO) throws {
        // Nil Check
        try isProjectDetailEmpty()
        
        // Add newTodo
        try setCoreFunction(with: dto)
        
        // Cleanup related Data
        try setCleanupFunction()
    }
    
    //--------------------
    // Get
    //--------------------
    func getTodoList() throws -> [TodoListDTO] {
        // Check & Sort Array
        sortTodoList()
        
        // Convert to TodoInfo
        return todoList.map{ TodoListDTO(with: $0) }
    }
    
    //--------------------
    // Update
    //--------------------
    // Desc
    func updateTodoDesc(todoId: Int, newDesc: String) throws {
        // Update Todo Description
        try updateCoreFunction(todoId: todoId, newDesc: newDesc)
    }
    
    // Status
    func updateTodoStatus(todoId: Int, newStatus: Bool) throws {
        // Nil Check
        try isProjectDetailEmpty()
        
        // Update Todo Status
        try updateCoreFunction(todoId: todoId, newStatus: newStatus)
        
        // Cleanup related Data
        try updateCleanupFunction(with: newStatus)
    }
    
    //TODO: Project Log Update
    //--------------------
    // Complete
    //--------------------
    func completeProject() throws {
        // Status Check
        if projectDetail.complete == false {
            throw ProjectDetailError.UnexpectedStatusError
        }
        let completeDate = Date()
        
        // Statistics Update :
        let statUpdate = StatUpdateDTO(
            userId: userId, newProjectFinished: statDTO.projectFinish + 1)
        try statCD.updateStatistics(with: statUpdate)
        
        // ProjectLog Update :
        let logUpdate = ProjectLogUpdateDTO(
            userId: userId, projectId: projectId,
            status: .finish, alertCount: projectDetail.alert, todoCount: projectDetail.todoRegist, finishAt: completeDate)
        try projectLogCD.updateLog(with: logUpdate)
        
        // Delete Project
        try projectCD.deleteProject(with: projectId, and: userId)
    }
}

//===============================
// MARK: Support Function:
// * Components
//===============================
extension ProjectDetailService{
    
    // Set: Core
    private func setCoreFunction(with dto: TodoSetDTO) throws {
        // 1. Add to Coredata
        let newTodo = try todoCD.setTodo(with: dto)
        
        // 2, Append Todo List
        todoList.append(newTodo)
    }
    // Set: CleanUp
    private func setCleanupFunction() throws {
        // Project: Todo Regist
        projectDetail.updateTodoRegist( with: projectDetail.todoRegist + 1 )
        try updateProjectTodoRegisted()
        
        // Statistics: Todo Regist
        statDTO.updateTodoRegist( with: statDTO.todoRegist + 1 )
        try updateStatTodoRegisted()
        
        // Check ProjectDetail
        try checkProjectStatus()
    }
    
    // Update: Core
    private func updateCoreFunction(todoId: Int, newDesc: String? = nil, newStatus: Bool? = nil) throws {
        if let desc = newDesc {
            let updated = TodoUpdateDTO(projectId: projectId, todoId: todoId, userId: userId, newDesc: desc)
            try todoCD.updateTodo(with: updated)
        }
        if let status = newStatus {
            let updated = TodoUpdateDTO(projectId: projectId, todoId: todoId, userId: userId, newStatus: status)
            try todoCD.updateTodo(with: updated)
        }
    }
    // Update: CleanUp
    private func updateCleanupFunction(with newStatus: Bool) throws {
        // Updated Status Check
        let adjustment = newStatus ? 1 : -1
        projectDetail.updateTodoFinish(
            with: projectDetail.todoFinish + adjustment)
        
        // Project: Todo Finish
        try updateProjectTodoFinished()
        
        // Check ProjectDetail
        try checkProjectStatus()
    }
}



//===============================
// MARK: Support Function:
// * ProjectDetail
//===============================
extension ProjectDetailService{
    
    // Check: Nil
    private func isProjectDetailEmpty() throws {
        if projectDetail.userId == "" || projectDetail.projectId == 0 {
            throw ProjectDetailError.UnexpectedInitializeError
        }
    }
    
    // Check: Project Status
    private func checkProjectStatus() throws {
        let newStatus = ( projectDetail.todoRemain == 0 )
        if projectDetail.complete != newStatus {
            projectDetail.updateProjectComplete(with: newStatus)
            try updateProjectCompleteStatus()
        }
    }
    // Update: Project Status
    private func updateProjectCompleteStatus() throws {
            let updated = ProjectUpdateDTO(
                userId: userId,
                projectId: projectId,
                newStatus: projectDetail.complete
            )
            try projectCD.updateProject(to: updated)
    }
    
    // Update: Todo Regist
    private func updateProjectTodoRegisted() throws {
        let updated = ProjectUpdateDTO(
            userId: userId,
            projectId: projectId,
            newTodoRegist: projectDetail.todoRegist
        )
        try projectCD.updateProject(to: updated)
    }
    
    // Update: Todo Finish
    private func updateProjectTodoFinished() throws {
        let updated = ProjectUpdateDTO(
            userId: userId,
            projectId: projectId,
            newTodoFinish: projectDetail.todoFinish
        )
        try projectCD.updateProject(to: updated)
    }
}

//===============================
// MARK: Support Function:
// * Statistics
//===============================
extension ProjectDetailService{
    
    // Update: Todo Registed
    private func updateStatTodoRegisted() throws {
        let updated = StatUpdateDTO(
            userId: userId, newTodoRegisted: statDTO.todoRegist)
        try statCD.updateStatistics(with: updated)
    }
    
    // Update: Project Finished
    private func updateStatProjectFinished() throws {
        let updated = StatUpdateDTO(
            userId: userId, newProjectFinished: statDTO.projectFinish)
        try statCD.updateStatistics(with: updated)
    }
}

//===============================
// MARK: Support Function:
// * Utilities & Etc
//===============================
extension ProjectDetailService{
    
    // Fetch List
    private func fetchTodoList() throws {
        let request = TodoRequestDTO(projectId: projectId, userId: userId)
        todoList = try todoCD.getTodoList(with: request)
    }
    
    // Array Sort
    private func sortTodoList() {
        // Check Array
        if todoList.isEmpty {
            return
        }
        // Divide Array
        let finishedTodo = todoList.filter{ $0.todo_status == true }
        let ongoingTodo = todoList.filter{ $0.todo_status == false }
        
        // Sort Each Array
        let sortedFinishedTodo = finishedTodo.sorted { $0.todo_changed_at > $1.todo_changed_at }
        let sortedOngoingTodo = ongoingTodo.sorted { $0.todo_registed_at > $1.todo_registed_at }
        
        // Apply Sorting
        self.todoList = sortedOngoingTodo + sortedFinishedTodo
    }
    
    // Delete Todo
    private func deleteTodoList() throws {
        for todo in todoList {
            try todoCD.deleteTodo(with: TodoRequestDTO(
                projectId: projectId,
                userId: userId,
                todoId: todo.todo_id)
            )
        }
    }
}



//===============================
// MARK: - Exception
//===============================
enum ProjectDetailError: LocalizedError {
    case UnexpectedFetchError
    case UnexpectedConvertError
    case UnexpectedSearchError
    case UnexpectedNilError
    case UnexpectedInitializeError
    case UnexpectedStatusError
    
    var errorDescription: String?{
        switch self {
        case .UnexpectedFetchError:
            return "Service: There was an unexpected error while Fetch 'Todo' details"
        case .UnexpectedConvertError:
            return "Service: There was an unexpected error while Convert 'Todo' details"
        case .UnexpectedSearchError:
            return "Service: There was an unexpected error while Search 'Todo' details"
        case .UnexpectedNilError:
            return "Service: There was an unexpected Nil error while Get 'ProjectDetail'"
        case .UnexpectedInitializeError:
            return "Service: There was an unexpected Initialize error In 'ProjectDetail'"
        case .UnexpectedStatusError:
            return "Service: There was an unexpected error while Check Project Complete Status in 'ProjectDetail'"
        }
    }
}
