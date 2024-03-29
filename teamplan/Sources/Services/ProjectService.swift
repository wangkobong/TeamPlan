//
//  ProjectService.swift
//  teamplan
//
//  Created by 크로스벨 on 3/29/24.
//  Copyright © 2024 team1os. All rights reserved.
//

import Foundation

final class ProjectService {
    
    private let coreValueCD: CoreValueServicesCoredata
    private let statCD: StatisticsServicesCoredata
    private let projectCD: ProjectServicesCoredata
    private let todoCD: TodoServiceCoredata
    private let util = Utilities()
    private let userId: String
    
    var statData: StatisticsObject = StatisticsObject()
    var coreValue: CoreValueObject = CoreValueObject()
    
    @Published var statDashBoard: ProjectStatDTO = ProjectStatDTO()
    @Published var projectList: [ProjectDTO] = []
    
    init(userId: String, controller: CoredataController = CoredataController()) {
        self.userId = userId
        self.coreValueCD = CoreValueServicesCoredata(coredataController: controller)
        self.statCD = StatisticsServicesCoredata(coredataController: controller)
        self.projectCD = ProjectServicesCoredata(coredataController: controller)
        self.todoCD = TodoServiceCoredata(coredataController: controller)
    }
    
    func prepareService() throws {
        self.statData = try statCD.getObject(with: userId)
        self.coreValue = try coreValueCD.getObject(with: userId)
        try getProjectList()
        try getStatDashBoard()
    }
}


// MARK: - Create NewProject
extension ProjectService {
    
    // condition check
    func canRegistNewProject() -> Bool {
        return self.projectList.count < self.coreValue.projectRegistLimit
    }
    
    // main function
    func setNewProject(title: String, startAt: Date, deadline: Date) throws {
        try createNewProject(title: title, startAt: startAt, deadline: deadline)
        try updateNewProjectRelated()
    }
    
    private func createNewProject(title: String, startAt: Date, deadline: Date) throws {
        let setDate = Date()
        let newId = statData.totalRegistedProjects + 1
        let newProject = ProjectObject(
            projectId: newId,
            userId: userId,
            title: title,
            status: .ongoing,
            todos: [],
            totalRegistedTodo: 0,
            dailyRegistedTodo: 0,
            finishedTodo: 0,
            alerted: 0,
            extendedCount: 0,
            registedAt: setDate,
            startedAt: startAt,
            deadline: deadline,
            finishedAt: setDate,
            syncedAt: setDate
        )
        try projectCD.setObject(with: newProject)
    }
    private func updateNewProjectRelated() throws {
        try updateProjectStatObject(type: .newProject)
        try updateProjectStatDTO(type: .newProject)
        try updateServiceProperties()
    }
}


// MARK: - Create NewTodo
extension ProjectService {
    
    // condition check
    func canRegistNewTodo(with dto: ProjectDTO) -> Bool {
        return dto.todoCanRegist > 0
    }
    
    // main function
    func setNewTodo(projectId: Int) throws {
        let newTodoId = try projectCD.getObject(with: userId, and: projectId).totalRegistedTodo + 1
        let newTodo = try createNewTodo(projectId: projectId, newTodoId: newTodoId)
        try updateNewTodoRelated(with: projectId, newTodo: newTodo)
    }
    
    private func createNewTodo(projectId: Int, newTodoId: Int) throws -> TodoDTO {
        let newTodo = TodoObject(
            projectId: projectId,
            todoId: newTodoId,
            userId: userId,
            desc: "",
            pinned: false,
            status: .ongoing
        )
        try todoCD.setObject(with: newTodo)
        return TodoDTO(with: newTodo)
    }
    private func updateNewTodoRelated(with projectId: Int, newTodo: TodoDTO) throws {
        try updateProjectObject(with: projectId, .newTodo(newTodo: newTodo))
        try updateProjectDTO(with: projectId, .newTodo(newTodo: newTodo))
        try updateProjectStatObject(type: .newTodo)
        try updateServiceProperties()
    }
}


// MARK: - Get ProjectList & StatDashBoard
extension ProjectService {
    
    private func getProjectList() throws {
        let projectObjects = try projectCD.getObjects(with: userId)
        for object in projectObjects {
            if object.status == .ongoing{
                self.projectList.append(try convertToProjectDTO(data: object, registLimit: self.coreValue.todoRegistLimit))
            }
        }
    }
    
    private func checkProjectStatus(with: ProjectObject) throws {
        // TODO: sort project by status
        // TODO: define project status by deadline, if exceed change status
    }
    
    private func getStatDashBoard() throws {
        self.statDashBoard = ProjectStatDTO(object: statData)
    }
}


// MARK: - Extend Support
extension ProjectService {
    
    // condition check
    func isDropEnough(inputDrop: Int) -> Bool {
        return statData.drop > inputDrop
    }
    
    // Convert inputDrop to newDeadLine
    func calcDeadLineWithDrop(projectId: Int, inputDrop: Int) throws -> Date {
        let convertRatio = coreValue.dropConvertRatio
        let storedDrop = statData.drop
        let index = try searchProjectIndex(with: projectId)
        
        let currentDeadline = self.projectList[index].deadline
        let extend = inputDrop * Int(convertRatio)
        
        guard let updatedDeadline = Calendar.current.date(byAdding: .day, value: extend, to: currentDeadline) else {
            // TODO: Custom Error
            throw CoredataError.convertFailure(serviceName: .project)
        }
        return updatedDeadline
    }
    
    // Convert newDeadLine to needDrop
    func calcDeadlineWithDate(with projectId: Int, and newDate: Date) throws -> Int {
        let convertRatio = coreValue.dropConvertRatio
        let storedDrop = statData.drop
        let index = try searchProjectIndex(with: projectId)
        
        let currentDeadline = self.projectList[index].deadline
        let component = Calendar.current.dateComponents([.day], from: currentDeadline, to: newDate)
        
        guard let extendDays = component.day else {
            // TODO: Custom Error
            throw CoredataError.convertFailure(serviceName: .project)
        }
        return extendDays * Int(convertRatio)
    }
}


// MARK: - Project Related
extension ProjectService {
    
    // extend
    func extendProject(projectId: Int, usedDrop: Int, newDeadline: Date, newTitle: String) throws {
        try updateProjectObject(with: projectId, .extend(newDeadline: newDeadline, newTitle: newTitle))
        try updateProjectDTO(with: projectId, .extend(newDeadline: newDeadline, newTitle: newTitle))
        try updateProjectStatObject(type: .extend(usedDrop: usedDrop))
        try updateServiceProperties()
    }
    
    // delete
    func deleteProject(projectId: Int) throws {
        try updateProjectObject(with: projectId, .delete)
        try updateProjectDTO(with: projectId, .delete)
    }
    
    // explode
    func explodeProject(projectId: Int) throws {
        try updateProjectObject(with: projectId, .explode)
        try updateProjectDTO(with: projectId, .explode)
        try updateProjectStatObject(type: .explode)
        try updateServiceProperties()
    }
    
    // complete
    func isProjectCompletable(_ dto: ProjectDTO) -> Bool {
        return dto.todoRemain == 0
    }
    
    func completeProject(projectId: Int) throws {
        try updateProjectObject(with: projectId, .complete)
        try updateProjectDTO(with: projectId, .complete)
        try updateProjectStatObject(type: .complete)
        try updateProjectStatDTO(type: .complete)
        try updateServiceProperties()
    }
}


// MARK: - Todo Related
extension ProjectService {
    
    func updateTodoDesc(with projectId: Int, todoId: Int, newDesc: String) throws {
        try updateTodoObject(with: projectId, and: todoId, .newDesc(newDesc: newDesc))
        try updateTodoDTO(with: projectId, and: todoId, .newDesc(newDesc: newDesc))
    }
    
    func updateTodoStatus(with projectId: Int, todoId: Int, newStatus: TodoStatus) throws {
        try updateTodoObject(with: projectId, and: todoId, .newStatus(newStatus: newStatus))
        try updateTodoDTO(with: projectId, and: todoId, .newStatus(newStatus: newStatus))
    }
}


// MARK: - Util
extension ProjectService {
    
    private func calcPeriod(deadline: Date) throws -> Int {
        return try util.calculateDatePeroid(with: Date(), and: deadline)
    }
    
    private func calcTodoRemain(registedTodo: Int, finishedTodo: Int) -> Int {
        let result = registedTodo - finishedTodo
        if result < 0 { return 0 }
        return result
    }
    
    private func calcTodoCanRegist(registLimit: Int, dailyRegisted: Int) -> Int {
        let result = registLimit - dailyRegisted
        if result < 0 { return 0 }
        return 0
    }
    
    private func searchProjectIndex(with projectId: Int) throws -> Int {
        guard let index = self.projectList.firstIndex(where: { $0.projectId == projectId }) else {
            // TODO: Custom Error
            throw CoredataError.fetchFailure(serviceName: .project)
        }
        return index
    }
    
    private func searchTodoIndex(with projectIndex: Int, and todoId: Int) throws -> Int  {
        guard let index = self.projectList[projectIndex].todoList.firstIndex(where: { $0.todoId == todoId }) else {
            // TODO: Custom Error
            throw CoredataError.fetchFailure(serviceName: .project)
        }
        return index
    }
    
    private func sortTodoList(with list: inout [TodoDTO]) {
        list.sort { (todo1, todo2) in
            if todo1.status == todo2.status {
                return todo1.todoId > todo2.todoId
            } else {
                return todo1.status == .ongoing
            }
        }
    }
    
    private func convertToProjectDTO(data: ProjectObject, registLimit: Int) throws -> ProjectDTO {
        var todoList = try todoCD.getObjects(userId: userId, projectId: data.projectId).map { TodoDTO(with: $0) }
        sortTodoList(with: &todoList)
        
        let dto = ProjectDTO(
            userId: userId,
            projectId: data.projectId,
            title: data.title,
            status: data.status,
            period: try calcPeriod(deadline: data.deadline),
            startAt: data.startedAt,
            deadline: data.deadline,
            todoRemain: calcTodoRemain(registedTodo: data.totalRegistedTodo, finishedTodo: data.finishedTodo),
            todoCanRegist: calcTodoCanRegist(registLimit: registLimit, dailyRegisted: data.dailyRegistedTodo),
            todoList: todoList
        )
        return dto
    }
    
    private func updateServiceProperties() throws {
        self.statData = try statCD.getObject(with: userId)
    }
}


// MARK: - Update
enum ProjectUpdateAction {
    case newTodo(newTodo: TodoDTO)
    case extend(newDeadline: Date, newTitle: String)
    case delete
    case explode
    case complete
    case updateTodo(newStatus: TodoStatus)
}

enum ProjectStatUpdateAction {
    case newProject
    case newTodo
    case extend(usedDrop: Int)
    case delete
    case explode
    case complete
}

enum TodoUpdateAction {
    case newDesc(newDesc: String)
    case newStatus(newStatus: TodoStatus)
}

extension ProjectService {
    
    // Project Object
    private func updateProjectObject(with projectId: Int, _ type: ProjectUpdateAction) throws {
        let data = try projectCD.getObject(with: userId, and: projectId)
        var updated = ProjectUpdateDTO(projectId: projectId, userId: userId)
        
        switch type {
        case .newTodo:
            updated.newTotalRegistedTodo = data.totalRegistedTodo + 1
            updated.newDailyRegistedTodo = data.dailyRegistedTodo + 1
        case .extend(let newDeadline, let newTitle):
            updated.newDeadline = newDeadline
            updated.newTitle = newTitle
            updated.newExtendedCount = data.extendedCount + 1
        case .delete:
            updated.newStatus = .deleted
            updated.newFinishedAt = Date()
        case .explode:
            updated.newStatus = .exploded
            updated.newFinishedAt = Date()
        case .complete:
            updated.newStatus = .finished
            updated.newFinishedAt = Date()
        case .updateTodo(let status):
            if status == .finish { updated.newFinishedTodo = data.finishedTodo + 1 }
            if status == .ongoing { updated.newFinishedTodo = data.finishedTodo - 1 }
        }
        try projectCD.updateObject(with: updated)
    }
    
    // Project DTO
    private func updateProjectDTO(with projectId: Int, _ type: ProjectUpdateAction) throws {
        let index = try searchProjectIndex(with: projectId)
        
        switch type {
        case .newTodo(let newTodo):
            self.projectList[index].todoRemain += 1
            self.projectList[index].todoCanRegist -= 1
            self.projectList[index].todoList.append(newTodo)
            sortTodoList(with: &self.projectList[index].todoList)
        case .extend(let newDeadline, let newTitle):
            self.projectList[index].title = newTitle
            self.projectList[index].deadline = newDeadline
            self.projectList[index].period = try calcPeriod(deadline: newDeadline)
        case .updateTodo(let status):
            if status == .finish { self.projectList[index].todoRemain -= 1 }
            if status == .ongoing { self.projectList[index].todoRemain += 1 }
        case .delete, .explode, .complete:
            self.projectList.remove(at: index)
        }
    }
    
    // Todo Object
    private func updateTodoObject(with projectId: Int, and todoId: Int, _ type: TodoUpdateAction) throws {
        var updated = TodoUpdateDTO(projectId: projectId, todoId: todoId, userId: userId)
        
        switch type {
        case .newDesc(let desc):
            updated.newDesc = desc
        case .newStatus(let status):
            updated.newStatus = status
        }
        try todoCD.updateObject(updated: updated)
    }
    
    // Todo DTO
    private func updateTodoDTO(with projectId: Int, and todoId: Int, _ type: TodoUpdateAction) throws {
        let projectIndex = try searchProjectIndex(with: projectId)
        let todoIndex = try searchTodoIndex(with: projectIndex, and: todoId)
        
        switch type {
        case .newDesc(let desc):
            self.projectList[projectIndex].todoList[todoIndex].desc = desc
        case .newStatus(let status):
            self.projectList[projectIndex].todoList[todoIndex].status = status
        }
    }
    
    // Stat Object
    private func updateProjectStatObject(type: ProjectStatUpdateAction) throws {
        var updated = StatUpdateDTO(userId: userId)
        
        switch type {
        case .newProject:
            updated.newTotalRegistedProjects = statData.totalRegistedProjects + 1
        case .newTodo:
            updated.newTotalRegistedTodos = statData.totalRegistedTodos + 1
        case .extend(let usedDrop):
            updated.newDrop = statData.drop - usedDrop
            updated.newTotalExtendedProjects = statData.totalExtendedProjects + 1
        case .delete:
            break
        case .explode:
            updated.newTotalFailedProjects = statData.totalFailedProjects + 1
        case .complete:
            updated.newTotalFinishedProjects = statData.totalFinishedProjects + 1
        }
        try statCD.updateObject(with: updated)
    }
    
    // Stat DTO
    private func updateProjectStatDTO(type: ProjectStatUpdateAction) throws {
        switch type {
        case .newProject:
            self.statDashBoard.registedProject += 1
        case .extend(let usedDrop):
            self.statDashBoard.storagedDrop -= usedDrop
        case .complete:
            self.statDashBoard.finishedProject += 1
        case .delete, .explode, .newTodo:
            break
        }
    }
}


// MARK: - DTO
// Project DashBoard
struct ProjectStatDTO {
    
    var registedProject: Int
    var finishedProject: Int
    var storagedDrop: Int
    
    init(object: StatisticsObject) {
        self.registedProject = object.totalRegistedProjects
        self.finishedProject = object.totalFinishedProjects
        self.storagedDrop = object.drop
    }
    init(){
        self.registedProject = 0
        self.finishedProject = 0
        self.storagedDrop = 0
    }
}

// Project
struct ProjectDTO {
    
    let userId: String
    let projectId: Int
    var title: String
    var status: ProjectStatus
    var period: Int
    let startAt: Date
    var deadline: Date
    var todoRemain: Int
    var todoCanRegist: Int
    var todoList: [TodoDTO]
    
    init(userId: String,
         projectId: Int,
         title: String,
         status: ProjectStatus,
         period: Int,
         startAt: Date,
         deadline: Date,
         todoRemain: Int,
         todoCanRegist: Int,
         todoList: [TodoDTO]
    ) {
        self.userId = userId
        self.projectId = projectId
        self.title = title
        self.status = status
        self.period = period
        self.startAt = startAt
        self.deadline = deadline
        self.todoRemain = todoRemain
        self.todoCanRegist = todoCanRegist
        self.todoList = todoList
    }
    
    init(tempDate: Date = Date()){
        self.userId = ""
        self.projectId = 0
        self.title = ""
        self.status = .unknown
        self.period = 0
        self.startAt = tempDate
        self.deadline = tempDate
        self.todoRemain = 0
        self.todoCanRegist = 0
        self.todoList = []
    }
}

// Todo
struct TodoDTO {
    let todoId: Int
    var desc: String
    var pinned: Bool
    var status: TodoStatus

    init(with object: TodoObject){
        self.todoId = object.todoId
        self.desc = object.desc
        self.pinned = object.pinned
        self.status = object.status
    }
}
