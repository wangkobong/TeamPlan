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
    let todoCD = TodoServiceCoredata()
    let statCD = StatisticsServicesCoredata()
    let util = Utilities()
    
    let projectId: Int
    let userId: String
    var todoList: [TodoObject] = []
    var statDTO: StatTodoDTO
    
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
        // Ready for Components
        let object = try projectCD.getProject(from: projectId, and: userId)
        let period = try util.calculateDatePeroid(with: object.proj_started_at, and: object.proj_deadline)
        statDTO = try statCD.getStatisticsForDTO(with: userId, type: .todo) as! StatTodoDTO
        
        // Struct Detail
        projectDetail = ProjectDetailDTO(
            with: object,
            period: period,
            limit: statDTO.todoLimit
        )
        // Reset TodoArray (For Inside Service Only)
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
        // Check ProjectDetail
        try checkProjectDetail()
        
        // Add NewTodo
        try todoCD.setTodo(with: dto)
        
        // Update TodoRegist Value
        projectDetail.updateTodoRegist(
            with: projectDetail.todoRegisted + 1)
        try updateProjectDetail()
        statDTO.updateTodoRegist(
            with: statDTO.todoRegist + 1)
        try updateStatisticsDTO()
    }
    
    //--------------------
    // Get
    //--------------------
    func getTodoList() throws -> [TodoInfo] {
        // Check & Sort Array
        sortTodoList()
        
        // Convert to TodoInfo
        return todoList.map{ TodoInfo(with: $0) }
    }
    
    //--------------------
    // Update
    //--------------------
    // Desc
    func updateTodoDesc(todoId: Int, newDesc: String) throws {
        // Struct UpdateDTO
        let updated = TodoUpdateDTO(
            projectId: projectId,
            todoId: todoId,
            userId: userId,
            newDesc: newDesc
        )
        // Apply Update
        try todoCD.updateTodo(with: updated)
    }
    // Status
    func updateTodoStatus(todoId: Int, newStatus: Bool) throws {
        // Struct UpdateDTO
        let updated = TodoUpdateDTO(
            projectId: projectId,
            todoId: todoId,
            userId: userId,
            newStatus: newStatus
        )
        // Apply Update
        try todoCD.updateTodo(with: updated)
    }
    // Pinned (Optional)
    
    //--------------------
    // Delete (For Reward Function)
    //--------------------
    func deleteTodoList() throws {
        for todo in todoList {
            try todoCD.deleteTodo(with: TodoRequestDTO(
                projectId: projectId,
                userId: userId,
                todoId: todo.todo_id)
            )
        }
    }
    
    //--------------------
    // Reward : Working Progress
    //--------------------
}

//===============================
// MARK: Support Function
//===============================
extension ProjectDetailService{
    
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
    
    // ProjectDetail Check
    private func checkProjectDetail() throws {
        if projectDetail.userId == "" || projectDetail.projectId == 0 {
            throw ProjectDetailError.UnexpectedInitializeError
        }
    }
    
    // ProjectDetail Update
    private func updateProjectDetail() throws {
        let updated = ProjectUpdateDTO(with: projectDetail)
        try projectCD.updateProject(to: updated)
    }
    
    // StatisticsDTO Update
    private func updateStatisticsDTO() throws {
        let updated = StatUpdateDTO(todoDTO: statDTO)
        try statCD.updateStatistics(with: updated)
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
        }
    }
}
