//
//  ProjectService.swift
//  teamplan
//
//  Created by 크로스벨 on 6/9/24.
//  Copyright © 2024 team1os. All rights reserved.
//

import Foundation

final class ProjectService {
    
    // Published
    
    var statDTO: StatDTO
    var projectList: [ProjectDTO]
    var projectRegistLimit: Int
    
    // Private
    
    private let util: Utilities
    private let userId: String
    private let storageManager: LocalStorageManager

    private let statCD: StatisticsServicesCoredata
    private let coreValueCD: CoreValueServicesCoredata
    private let projectCD: ProjectServicesCoredata
    private let todoCD: TodoServiceCoredata
    
    private var coreValue: CoreValueObject
    
    init(userId: String, statData: StatDTO) {
        self.statDTO = statData
        self.projectList = []
        self.projectRegistLimit = 0
        
        self.util = Utilities()
        self.userId = userId
        self.storageManager = LocalStorageManager.shared
        
        self.statCD = StatisticsServicesCoredata()
        self.coreValue = CoreValueObject()
        self.coreValueCD = CoreValueServicesCoredata()
        self.projectCD = ProjectServicesCoredata()
        self.todoCD = TodoServiceCoredata()
    }
}

//MARK: Service - Executor

enum ProjectServiceAction {
    case prepareService
    case setNewProject(newData: NewProjectDTO, setDate: Date)
    case renameProject(projectId: Int, newTitle: String)
    case deleteProject(projectId: Int)
    case extendProject(dto: ExtendProjectDTO)
    case completeProject(projectId: Int, completeDate: Date)
    case setNewTodo(projectId: Int)
    case updateTodoStatus(projectId: Int, todoId: Int, newStatus: TodoStatus)
    case updateTodoDesc(projectId: Int, todoId: Int, newDesc: String)
    
    var desc: String {
        switch self {
        case .prepareService:
            return "prepareService"
        case .setNewProject:
            return "setNewProject"
        case .renameProject:
            return "renameProject"
        case .deleteProject:
            return "deleteProject"
        case .extendProject:
            return "extendProject"
        case .completeProject:
            return "completeProject"
        case .setNewTodo:
            return "setNewTodo"
        case .updateTodoStatus:
            return "updateTodoStatus"
        case .updateTodoDesc:
            return "updateTodoDesc"
        }
    }
}

extension ProjectService {
    
    // main executor: manage retry action
    func executor(action: ProjectServiceAction) async -> Bool {
        let max = 3
        var retryCount = 1
        var isProcessComplete = false
        
        while retryCount <= max && !isProcessComplete {
            isProcessComplete = await executeServiceAction(action)
            
            if !isProcessComplete {
                print("[ProjectService] Retrying \(action.desc) action... \(retryCount)/\(max)")
                retryCount += 1
            }
        }
        
        if !isProcessComplete {
            print("[ProjectService] Failed to execute \(action.desc) action after \(max) retries")
            return false
        } else {
            print("[ProjectService] Successfully executed \(action.desc) action in \(retryCount) tries")
            return true
        }
    }
    
    // sub executor: manage service action
    private func executeServiceAction(_ action: ProjectServiceAction) async -> Bool {
        switch action {
        case .prepareService:
            return await prepareServiceData()
        case .setNewProject(let newData, let setDate):
            return await setNewProjectProcess(with: newData, on: setDate)
        case .renameProject(let projectId, let newTitle):
            return await renameProjectProcess(with: projectId, and: newTitle)
        case .deleteProject(let projectId):
            return await deleteProjectProcess(with: projectId)
        case .extendProject(let dto):
            return await extendProjectProcess(with: dto)
        case .completeProject(let projectId, let completeDate):
            return await completeProjectProcess(with: projectId, at: completeDate)
        case .setNewTodo(let projectId):
            return await setNewTodoProcess(with: projectId)
        case .updateTodoStatus(let projectId, let todoId, let newStatus):
            return await updateTodoStatusProcess(with: projectId, and: todoId, newStatus: newStatus)
        case .updateTodoDesc(let projectId, let todoId, let newDesc):
            return await updateTodoDescProcess(with: projectId, and: todoId, newDesc: newDesc)
        }
    }
}

//MARK: Service - PrepareData

extension ProjectService {
    
    // executor
    private func prepareServiceData() async -> Bool {
        async let statReady = prepareStatData()
        async let coreValueReady = prepareCoreValueData()
        async let projectReady = prepareProjectData()
        
        let results = await [statReady, coreValueReady, projectReady]
        if results.allSatisfy({$0}) {
            self.projectRegistLimit = self.coreValue.projectRegistLimit
            return true
        } else {
            return false
        }
    }
    
    // fetch
    private func prepareStatData() async -> Bool {
        do {
            let statObject = try statCD.getObject(with: userId)
            self.statDTO = StatDTO(with: statObject)

            return true
        } catch {
            print("[ProjectService] Failed to prepare StatData")
            return false
        }
    }
    
    // fetch
    private func prepareCoreValueData() async -> Bool {
        do {
            self.coreValue = try coreValueCD.getObject(with: userId)
            return true
        } catch {
            print("[ProjectService] Failed to prepare CoreValueData")
            return false
        }
    }
    
    // fetch
    private func prepareProjectData() async -> Bool {
        do {
            let projectObjectList = try projectCD.getValidObjects(with: userId)
            for object in projectObjectList {
                self.projectList.append(try await convertExistObjectToDTO(with: object))
            }
            return true
        } catch {
            print("[ProjectService] Failed to prepare ProjectData")
            return false
        }
    }
}

//MARK: Project - Create

struct NewProjectDTO {
    
    let title: String
    let startAt: Date
    let deadline: Date
    let setDate: Date
    
    init(
         title: String,
         startAt: Date,
         deadline: Date,
         setDate: Date)
    {
        self.title = title
        self.startAt = startAt
        self.deadline = deadline
        self.setDate = setDate
    }
}

extension ProjectService {
    
    // shared
    func canRegistNewProject() -> Bool {
        return self.projectList.count < self.coreValue.projectRegistLimit
    }
    
    // executor
    private func setNewProjectProcess(with newData: NewProjectDTO, on setDate: Date) async -> Bool {
        let newProject = createNewProject(with: newData)

        guard await saveProjectToStorage(with: newProject) else {
            print("[ProjectService] Stop set new project process")
            return false
        }
        
        let isAppendToList = await appendProjectToList(with: newProject)
        let isStatDataUpdated = await updateStatDataAboutProjectCreation()

        return isAppendToList && isStatDataUpdated
    }
    
    // creator
    private func createNewProject(with newData: NewProjectDTO) -> ProjectObject {
        let newId = statDTO.totalRegistedProjects
        let dailyTodoRegistLimit = coreValue.todoRegistLimit
        
        return ProjectObject(
            projectId: newId,
            userId: userId,
            title: newData.title,
            status: .ongoing,
            todos: [],
            totalRegistedTodo: 0,
            dailyRegistedTodo: dailyTodoRegistLimit,
            finishedTodo: 0,
            alerted: 0,
            extendedCount: 0,
            registedAt: newData.setDate,
            startedAt: newData.startAt,
            deadline: newData.deadline,
            finishedAt: newData.setDate,
            syncedAt: newData.setDate
        )
    }
    
    // update: projectObject
    private func saveProjectToStorage(with object: ProjectObject) async -> Bool {
        
        guard projectCD.setObject(with: object) else {
            print("[ProjectService] Failed to set new project data at storage context")
            return false
        }
        
        guard await storageManager.saveContext() else {
            print("[ProjectService] Failed to apply new project data at storage")
            return false
        }
        return true
    }
    
    // update: projectDTO
    private func appendProjectToList(with object: ProjectObject) async -> Bool {
        do {
            let dto = try await convertNewObjectToDTO(with: object)
            self.projectList.append(dto)
            return true
        } catch {
            print("[ProjectService] Failed to append project data at list")
            return false
        }
    }
    
    // update: statObject & DTO
    private func updateStatDataAboutProjectCreation() async -> Bool {
        var updated = StatUpdateDTO(userId: userId)
        let currentValue = self.statDTO.totalRegistedProjects
        let updatedValue = self.statDTO.totalRegistedProjects + 1
        
        updated.newTotalRegistedProjects = updatedValue
        self.statDTO.totalRegistedProjects = updatedValue
        
        do {
            guard try statCD.updateObject(with: updated) else {
                print("[ProjectService] StatObject change not detected")
                self.statDTO.totalRegistedProjects = currentValue
                return false
            }
            guard await storageManager.saveContext() else {
                print("[ProjectService] Failed to apply updated StatObject at storage")
                self.statDTO.totalRegistedProjects = currentValue
                return false
            }
            return true
            
        } catch {
            print("[ProjectService] Failed to get original StatObject: \(error.localizedDescription)")
            self.statDTO.totalRegistedProjects = currentValue
            return false
        }
    }
}

//MARK: Project - Rename

extension ProjectService {
    
    // executor
    private func renameProjectProcess(with projectId: Int, and newTitle: String) async -> Bool {
        do {
            // search project at list
            let index = try await searchProjectIndex(with: projectId)
            
            // update object, then dto
            if await updateProjectObjectAboutRename(with: newTitle, and: index) {
                updateProjectDTOAboutRename(with: newTitle, and: index)
                return true
                
            // exception handling
            } else {
                print("[ProjectService] Stop rename project process")
                return false
            }
        } catch {
            print("[ProjectService] Stop rename project process")
            return false
        }
    }
    
    // update: projectObject
    private func updateProjectObjectAboutRename(with newTitle: String, and index: Int) async -> Bool {
        let updated = ProjectUpdateDTO(projectId: projectList[index].projectId, userId: userId, newTitle: newTitle)

        do {
            guard try projectCD.updateObject(with: updated) else {
                print("[ProjectService] ProjectObject change not detected")
                return false
            }
            
            guard await storageManager.saveContext() else {
                print("[ProjectService] Failed to apply updated ProjectObject at storage")
                return false
            }
            return true
            
        } catch {
            print("[ProjectService] Failed to get original projectObject: \(error.localizedDescription)")
            return false
        }
    }
    
    // update: projectDTO
    private func updateProjectDTOAboutRename(with newTitle: String, and index: Int) {
        projectList[index].title = newTitle
    }
}

//MARK: Project - Delete

extension ProjectService {
    
    // executor
    private func deleteProjectProcess(with projectId: Int) async -> Bool {
        
        // delete object
        let isProjectObjectDeleted = await updateProjectObjectAboutDelete(with: projectId)
        let isProjectDTOdeleted = await updateProjectDTOAboutdelete(with: projectId)
        
        if isProjectObjectDeleted && isProjectDTOdeleted {
            return true
        } else {
            print("[ProjectService] Stop delete project process")
            return false
        }
    }
    
    // update: projectObject
    private func updateProjectObjectAboutDelete(with projectId: Int) async -> Bool {
        do {
            try projectCD.deleteObject(with: userId, and: projectId)
            
            guard await storageManager.saveContext() else {
                print("[ProjectService] Failed to apply delete ProjectObject at storage")
                return false
            }
            return true
            
        } catch {
            print("[ProjectService] Failed to get original projectObject: \(error.localizedDescription)")
            return false
        }
    }
    
    // update: projectDTO
    private func updateProjectDTOAboutdelete(with projectId: Int) async -> Bool {
        do {
            let index = try await searchProjectIndex(with: projectId)
            self.projectList.remove(at: index)
            return true
        } catch {
            print("[ProjectService] Failed to Delete ProjectDTO")
            return false
        }
    }
}

//MARK: Project - Extend

struct ExtendProjectDTO {
    let projectId: Int
    let usedDrop: Int
    let newDeadline: Date
    
    init(projectId: Int,
         usedDrop: Int,
         newDeadline: Date
    ) {
        self.projectId = projectId
        self.usedDrop = usedDrop
        self.newDeadline = newDeadline
    }
}

extension ProjectService {
    
    // executor
    private func extendProjectProcess(with dto: ExtendProjectDTO) async -> Bool {
        do {
            // get index
            let index = try await searchProjectIndex(with: dto.projectId)
            
            // update object, then update dto
            if await updateProjectObjectAboutExtend(with: dto.projectId, and: dto.newDeadline) {
                let isProjectDTOUpdated = await updateProjectDTOAboutExtend(with: dto.newDeadline, and: index)
                let isStatDataUpdated = await updateStatDataAboutExtend(with: dto.usedDrop)

                return isProjectDTOUpdated && isStatDataUpdated
            } else {
                print("[ProjectService] Failed to update project object in storage")
                return false
            }
        } catch {
            print("[ProjectService] Failed to search ProjectDTO")
            return false
        }
    }
    
    // update: projectUpdate
    private func updateProjectObjectAboutExtend(with projectId: Int, and newDeadline: Date) async -> Bool {
        let previousObject: ProjectObject
        var updated = ProjectUpdateDTO(projectId: projectId, userId: userId)
        
        // fetch object
        do {
            previousObject = try projectCD.getObject(with: userId, and: projectId)
        } catch {
            print("[ProjectService] Failed to fetch projectObject")
            return false
        }
        
        // update object
        updated.newDeadline = newDeadline
        updated.newExtendedCount = previousObject.extendedCount + 1
        
        do {
            guard try projectCD.updateObject(with: updated) else {
                print("[ProjectService] ProjectObject change not detected")
                return false
            }
            
            guard await storageManager.saveContext() else {
                print("[ProjectService] Failed to apply extend ProjectObject at storage")
                return false
            }
            return true
            
        } catch {
            print("[ProjectService] Failed to get original projectObject: \(error.localizedDescription)")
            return false
        }
    }
    
    // update: projectDTO
    private func updateProjectDTOAboutExtend(with newDeadline: Date, and index: Int) async -> Bool {
        do {
            let today = Date()
            let newTotalPeriod = try util.calculateDatePeriod(with: projectList[index].startAt, and: newDeadline)
            let newRemainDays = try util.calculateDatePeriod(with: today, and: newDeadline)
            
            projectList[index].deadline = newDeadline
            projectList[index].totalPeriod = newTotalPeriod
            projectList[index].remainDays = newRemainDays
            
            return true
        } catch {
            print("[ProjectService] Failed to calculate new project period")
            return false
        }
    }
    
    // update: statObject & statDTO
    private func updateStatDataAboutExtend(with usedDrop: Int) async -> Bool {
        var updated = StatUpdateDTO(userId: userId)
        let updatedVaule = self.statDTO.totalExtendedProjects + 1
        let previousValue = self.statDTO.totalExtendedProjects
        
        updated.newTotalExtendedProjects = updatedVaule
        self.statDTO.totalExtendedProjects = updatedVaule
        
        do {
            guard try statCD.updateObject(with: updated) else {
                print("[ProjectService] StatObject change not detected")
                self.statDTO.totalExtendedProjects = previousValue
                return false
            }
            
            guard await storageManager.saveContext() else {
                print("[ProjectService] Failed to apply extend StatObject at storage")
                self.statDTO.totalExtendedProjects = previousValue
                return false
            }
            return true
            
        } catch {
            print("[ProjectService] Failed to get original StatObject: \(error.localizedDescription)")
            self.statDTO.totalExtendedProjects = previousValue
            return false
        }
    }
}

//MARK: Project - Complete

extension ProjectService {
    
    // shared
    func canCompleteProject(with projectId: Int) async -> Bool {
        do {
            let index = try await searchProjectIndex(with: projectId)
            return projectList[index].todoRemain == 0
        } catch {
            print("[ProjectService] Failed to search project index")
            return false
        }
    }
    
    // executor
    private func completeProjectProcess(with projectId: Int, at completeDate: Date) async -> Bool {
        do {
            if await !updateProjectObjectAboutComplete(with: projectId, at: completeDate) {
                print("[ProjectService] Stop complete project process")
                return false
            }
            // get index
            let index = try await searchProjectIndex(with: projectId)
            print("[ProjectService] projectId: \(projectId), index: \(index) ")
            
            if await !updateStatDataAboutComplete(with: index) {
                print("[ProjectService] Stop complete project process")
                return false
            }
            updateProjectDTOAboutComplete(with: index)
            return true
            
        } catch {
            print("[ProjectService] Failed to search ProjectDTO")
            return false
        }
    }
    
    // update: projectObject
    private func updateProjectObjectAboutComplete(with projectId: Int, at completeDate: Date) async -> Bool {
        
        // construct update info
        let updated = ProjectUpdateDTO(
            projectId: projectId,
            userId: userId,
            newStatus: .finished,
            newFinishedAt: completeDate
        )
        
        // update object
        do {
            guard try projectCD.updateObject(with: updated) else {
                print("[ProjectService] ProjectObject change not detected")
                return false
            }
            
            guard await storageManager.saveContext() else {
                print("[ProjectService] Failed to apply complete ProjectObject at storage")
                return false
            }
            print("[ProjectService] Successfully apply complete ProjectObject")
            return true
            
        } catch {
            print("[ProjectService] Failed to get original ProjectObject: \(error.localizedDescription)")
            return false
        }
    }
    
    // update: projectDTO
    private func updateProjectDTOAboutComplete(with index: Int) {
        let dto = self.projectList.remove(at: index)
    }
    
    // update: statObject & statDTO
    private func updateStatDataAboutComplete(with index: Int) async -> Bool {
        var updated = StatUpdateDTO(userId: userId)
        
        let currentTotalFinishedProjects = statDTO.totalFinishedProjects
        let updatedTotalFinishedProjects = currentTotalFinishedProjects + 1
        
        let currentTotalFinishedTodos = statDTO.totalFinishedTodos
        let updatedTotalFinishedTodos = currentTotalFinishedTodos + projectList[index].todoList.count
        
        updated.newTotalFinishedProjects = updatedTotalFinishedProjects
        updated.newTotalFinishedTodos = updatedTotalFinishedTodos
        
        do {
            guard try statCD.updateObject(with: updated) else {
                print("[ProjectService] StatObject change not detected")
                return false
            }
            
            guard await storageManager.saveContext() else {
                print("[ProjectService] Failed to apply complete StatObject at storage")
                return false
            }
            statDTO.totalFinishedProjects = updatedTotalFinishedProjects
            statDTO.totalFinishedTodos = updatedTotalFinishedTodos
            
            print("[ProjectService] Successfully apply complete StatObject")
            return true
        } catch {
            print("[ProjectService] Failed to get original StatObject: \(error.localizedDescription)")
            return false
        }
    }
}

//MARK: Project - Explode
// only update object
extension ProjectService {
    
    private func explodeProjectProcess(with projectId: Int, on explodeDate: Date) async -> Bool {
        async let isProjectObjectUpdated = updateProjectObjectAboutExplode(with: projectId, on: explodeDate)
        async let isStatObjectUpdated = updateStatObjectAboutExplode()
        
        let results = await [isProjectObjectUpdated, isStatObjectUpdated]
        
        if results.allSatisfy({ $0 }) {
            return true
        } else {
            print("[ProjectService] Failed to process explode ProjectObject")
            return false
        }
    }
    
    // update: projectObject
    private func updateProjectObjectAboutExplode(with projectId: Int, on explodeDate: Date) async -> Bool {
        
        // construct update info
        let updated = ProjectUpdateDTO(
            projectId: projectId,
            userId: userId,
            newStatus: .exploded,
            newFinishedAt: explodeDate
        )
        
        // update object
        do {
            guard try projectCD.updateObject(with: updated) else {
                print("[ProjectService] ProjectObject change not detected")
                return false
            }
            
            guard await storageManager.saveContext() else {
                print("[ProjectService] Failed to apply explode ProjectObject at storage")
                return false
            }
            return true
            
        } catch {
            print("[ProjectService] Failed to get original ProjectObject: \(error.localizedDescription)")
            return false
        }
    }
    
    // update: statObject
    private func updateStatObjectAboutExplode() async -> Bool {
        do {
            let currentValue = try statCD.getObject(with: userId).totalFailedProjects
            let updated = StatUpdateDTO(userId: userId, newTotalFailedProjects: currentValue + 1)
            
            guard try statCD.updateObject(with: updated) else {
                print("[ProjectService] StatObject change not detected")
                return false
            }
            
            guard await storageManager.saveContext() else {
                print("[ProjectService] Failed to apply explode StatObject at storage")
                return false
            }
            return true
            
        } catch {
            print("[ProjectService] Failed to get original StatisticsObject: \(error.localizedDescription)")
            return false
        }
    }
}

//MARK: Todo - Create

extension ProjectService {
    
    // shared
    func canRegistNewTodo(with projectId: Int) async -> Bool {
        do {
            let index = try await searchProjectIndex(with: projectId)
            return projectList[index].todoCanRegist > 0
        } catch {
            print("[ProjectService] Failed to search project index")
            return false
        }
    }
    
    // executor
    private func setNewTodoProcess(with projectId: Int) async -> Bool {
        do {
            let index = try await searchProjectIndex(with: projectId)
            let newTodoId = projectList[index].todoList.count + 1
            let newTodo = createNewTodoObject(with: projectId, and: newTodoId, index: index)
            
            guard await saveTodoAtStorage(with: newTodo) else {
                print("[ProjectService] Failed to save new todo at storage")
                return false
            }
            
            guard await updateProjectDataAboutTodoCreation(with: projectId, and: index) else {
                print("[ProjectService] Failed to update project data about todo creation")
                return false
            }
            
            await appendTodoAtList(with: newTodo, and: index)
            
            guard await updateStatDataAboutTodoCreation() else {
                print("[ProjectService] Failed to update stat data about todo creation")
                return false
            }
            
            return true
        } catch {
            print("[ProjectService] Failed to add new todo process: \(error)")
            return false
        }
    }

    // creator
    private func createNewTodoObject(with projectId: Int, and newTodoId: Int, index: Int) -> TodoObject {
        
        return TodoObject(
            projectId: projectId,
            todoId: newTodoId,
            userId: userId,
            desc: "",
            pinned: false,
            status: .ongoing
        )
    }

    // set: todoObject
    private func saveTodoAtStorage(with newTodo: TodoObject) async -> Bool {
        do {
            guard try todoCD.setObject(with: newTodo) else {
                print("[ProjectService] Failed to set new todo data at storage context")
                return false
            }
            
            guard await storageManager.saveContext() else {
                print("[ProjectService] Failed to apply new todo data at storage")
                return false
            }
            return true
            
        } catch {
            print("[ProjectService] Failed to search containing Project - [ ProjectId: \(newTodo.projectId) / TodoId: \(newTodo.todoId)]: \(error.localizedDescription)")
            return false
        }
    }

    // update: projectObject & DTO
    private func updateProjectDataAboutTodoCreation(with projectId: Int, and index: Int) async -> Bool {
        guard let current = await fetchProjectObject(with: projectId) else {
            return false
        }
        
        let newDailyRegistedTodo = current.dailyRegistedTodo - 1
        let newTotalRegistedTodo = current.totalRegistedTodo + 1
        let updated = ProjectUpdateDTO(
            projectId: projectId,
            userId: userId,
            newTotalRegistedTodo: newTotalRegistedTodo,
            newDailyRegistedTodo: newDailyRegistedTodo
        )
        
        guard await updateProjectObject(with: updated) else {
            return false
        }
        
        updateProjectDTOAboutTodoCreation(with: newDailyRegistedTodo, and: index)
        return true
    }

    // update: projectObject
    private func updateProjectObject(with updated: ProjectUpdateDTO) async -> Bool {
        do {
            guard try projectCD.updateObject(with: updated) else {
                print("[ProjectService] ProjectObject change not detected")
                return false
            }
            guard await storageManager.saveContext() else {
                print("[ProjectService] Failed to apply updated ProjectObject at storage")
                return false
            }
            return true
            
        } catch {
            print("[ProjectService] Failed to get original projectObject: \(error.localizedDescription)")
            return false
        }
    }

    // update: projectDTO
    private func appendTodoAtList(with newTodo: TodoObject, and index: Int) async {
        let todoDTO = TodoDTO(with: newTodo)
        self.projectList[index].todoList.append(todoDTO)
    }
    private func updateProjectDTOAboutTodoCreation(with dailyRegistedTodo: Int, and index: Int) {
        self.projectList[index].todoCanRegist = dailyRegistedTodo
        self.projectList[index].todoRemain += 1
    }

    // update: statObject & statDTO
    private func updateStatDataAboutTodoCreation() async -> Bool {
        let updated = StatUpdateDTO(
            userId: userId,
            newTotalRegistedTodos: self.statDTO.totalRegistedTodos + 1
        )
        do {
            guard try statCD.updateObject(with: updated) else {
                print("[ProjectService] StatObject change not detected")
                return false
            }
            
            guard await storageManager.saveContext() else {
                print("[ProjectService] Failed to apply updated StatObject at storage")
                return false
            }
            self.statDTO.totalRegistedTodos += 1
            return true
            
        } catch {
            print("[ProjectService] Failed to get original StatObject: \(error.localizedDescription)")
            return false
        }
    }
}

//MARK: Todo - UpdateStatus

extension ProjectService {
    
    // executor
    private func updateTodoStatusProcess(with projectId: Int, and todoId: Int, newStatus: TodoStatus) async -> Bool {
        guard let finishedTodoCount = await fetchFinishedTodoCount(for: projectId) else {
            print("[ProjectService] Failed to fetch finished todo count for project: [\(projectId)]")
            return false
        }
        
        do {
            let projectIndex = try await searchProjectIndex(with: projectId)
            let todoIndex = try await searchTodoIndex(with: projectIndex, and: todoId)
            let isTodoObjectUpdated = await updateTodoObjectStatus(with: projectId, and: todoId, to: newStatus)
            let isProjectObjectUpdated = await updateProjectFinishedTodoCount(with: projectId, currentCount: finishedTodoCount, newStatus: newStatus)
            
            if isTodoObjectUpdated && isProjectObjectUpdated {
                updateProjectDTOStatus(with: projectIndex, and: todoIndex, newStatus: newStatus)
                return true
            } else {
                return false
            }
        } catch {
            print("[ProjectService] Failed to search index for project: [\(projectId)]")
            return false
        }
    }

    // helper: fetch finished todo count
    private func fetchFinishedTodoCount(for projectId: Int) async -> Int? {
        guard let projectObject = await fetchProjectObject(with: projectId) else {
            print("[ProjectService] Failed to fetch project object for project: [\(projectId)]")
            return nil
        }
        return projectObject.finishedTodo
    }

    // update: todoObject
    private func updateTodoObjectStatus(with projectId: Int, and todoId: Int, to newStatus: TodoStatus) async -> Bool {
        let updated = TodoUpdateDTO(
            projectId: projectId,
            todoId: todoId,
            userId: userId,
            newStatus: newStatus
        )
        do {
            guard try todoCD.updateObject(updated: updated) else {
                print("[ProjectService] TodoObject change not detected: [\(todoId)] in project: [\(projectId)]")
                return false
            }
            
            guard await storageManager.saveContext() else {
                print("[ProjectService] Failed to apply updated TodoObject at storage: [\(todoId)] in project: [\(projectId)]")
                return false
            }
            return true
            
        } catch {
            print("[ProjectService] Failed to search original object for todo: [\(todoId)] in project: [\(projectId)] - \(error.localizedDescription)")
            return false
        }
    }

    // update: projectObject
    private func updateProjectFinishedTodoCount(with projectId: Int, currentCount: Int, newStatus: TodoStatus) async -> Bool {
        let updatedValue: Int
        
        switch newStatus {
        case .finish:
            updatedValue = currentCount + 1
        case .ongoing:
            updatedValue = currentCount - 1
        }
        
        let updated = ProjectUpdateDTO(
            projectId: projectId,
            userId: userId,
            newFinishedTodo: updatedValue
        )
        
        do {
            guard try projectCD.updateObject(with: updated) else {
                print("[ProjectService] ProjectObject change not detected")
                return false
            }
            guard await storageManager.saveContext() else {
                print("[ProjectService] Failed to apply updated ProjectObject at storage")
                return false
            }
            return true
            
        } catch {
            print("[ProjectService] Failed to get original projectObject: \(error.localizedDescription)")
            return false
        }
    }

    // update: projectDTO
    private func updateProjectDTOStatus(with projectIndex: Int, and todoIndex: Int, newStatus: TodoStatus) {
        switch newStatus {
        case .finish:
            self.projectList[projectIndex].todoRemain -= 1
        case .ongoing:
            self.projectList[projectIndex].todoRemain += 1
        }
        self.projectList[projectIndex].todoList[todoIndex].status = newStatus
    }
}

//MARK: Todo - UpdateDesc

extension ProjectService {
    private func updateTodoDescProcess(with projectId: Int, and todoId: Int, newDesc: String) async -> Bool {
        do {
            let projectIndex = try await searchProjectIndex(with: projectId)
            let todoIndex = try await searchTodoIndex(with: projectIndex, and: todoId)
            
            if await updateTodoObjectDesc(with: projectId, and: todoId, newDesc: newDesc) {
                await updateProjectDTODesc(with: projectIndex, and: todoIndex, newDesc: newDesc)
                return true
            } else {
                print("[ProjectService] Stop update todo description process")
                return false
            }
            
        } catch {
            print("[ProjectService] Failed to search index for project: [\(projectId)]")
            return false
        }
    }
    
    private func updateTodoObjectDesc(with projectId: Int, and todoId: Int, newDesc: String) async -> Bool {
        let updated = TodoUpdateDTO(projectId: projectId, todoId: todoId, userId: userId, newDesc: newDesc)
        
        do {
            guard try todoCD.updateObject(updated: updated) else {
                print("[ProjectService] TodoObject change not detected")
                return false
            }
            guard await storageManager.saveContext() else {
                print("[ProjectService] Failed to apply updated TodoObject at storage")
                return false
            }
            return true
            
        } catch {
            print("[ProjectService] Failed to search containing Project - [ ProjectId: \(projectId) / TodoId: \(todoId)]: \(error.localizedDescription)")
            return false
        }
    }
    
    private func updateProjectDTODesc(with projectIndex: Int, and todoIndex: Int, newDesc: String) async {
        self.projectList[projectIndex].todoList[todoIndex].desc = newDesc
    }
}

//MARK: Project DTO

struct ProjectDTO {
    
    let userId: String
    let projectId: Int
    var title: String
    var status: ProjectStatus
    let startAt: Date
    var deadline: Date
    var todoRemain: Int
    var todoCanRegist: Int
    var todoList: [TodoDTO]
    
    var totalPeriod: Int
    var progressedPeriod: Int
    var remainDays: Int
    
    // default
    init(tempDate: Date = Date()){
        self.userId = ""
        self.projectId = 0
        self.title = ""
        self.status = .unknown
        self.startAt = tempDate
        self.deadline = tempDate
        self.todoRemain = 0
        self.todoCanRegist = 0
        self.todoList = []
        self.totalPeriod = 0
        self.progressedPeriod = 0
        self.remainDays = 0
    }
    
    // onoging
    init(userId: String,
         projectId: Int,
         title: String,
         status: ProjectStatus,
         startAt: Date,
         deadline: Date,
         todoRemain: Int,
         todoCanRegist: Int,
         todoList: [TodoDTO],
         totalPeriod: Int,
         progressedPeriod: Int,
         remainDays: Int
    ) {
        self.userId = userId
        self.projectId = projectId
        self.title = title
        self.status = status
        self.startAt = startAt
        self.deadline = deadline
        self.todoRemain = todoRemain
        self.todoCanRegist = todoCanRegist
        self.todoList = todoList
        self.totalPeriod = totalPeriod
        self.progressedPeriod = progressedPeriod
        self.remainDays = remainDays
    }
}

//MARK: Todo DTO

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

//MARK: Converter

extension ProjectService {
    
    private func convertNewObjectToDTO(with object: ProjectObject) async throws -> ProjectDTO {
        let today = Date()
        let remainDays: Int
        let totalPeriod: Int
        
        // period calculation
        do {
            remainDays = try util.calculateDatePeriod(with: today, and: object.deadline)
            totalPeriod = try util.calculateDatePeriod(with: object.startedAt, and: object.deadline)
        } catch {
            print("[ProjectService] Failed to calculate project period at Object conversion")
            throw CoredataError.convertFailure(serviceName: .project, dataType: .project)
        }
        
        // construct object
        return ProjectDTO(
            userId: object.userId,
            projectId: object.projectId,
            title: object.title,
            status: object.status,
            startAt: object.startedAt,
            deadline: object.deadline,
            todoRemain: 0,
            todoCanRegist: object.dailyRegistedTodo,
            todoList: [],
            totalPeriod: totalPeriod,
            progressedPeriod: 0,
            remainDays: remainDays
        )
    }
    
    private func convertExistObjectToDTO(with object: ProjectObject) async throws -> ProjectDTO {
        let today = Date()
        let remainDays: Int
        let totalPeriod: Int
        let progressedPeriod: Int
        
        let todoRemain: Int
        let todoList: [TodoDTO]
        
        do {
            remainDays = try util.calculateDatePeriod(with: today, and: object.deadline)
            totalPeriod = try util.calculateDatePeriod(with: object.startedAt, and: object.deadline)
            progressedPeriod = try util.calculateDatePeriod(with: object.startedAt, and: today)
            
            todoRemain = object.totalRegistedTodo - object.finishedTodo
            todoList = object.todos.map { TodoDTO(with: $0) }
        } catch {
            print("[ProjectService] Failed to convert object data")
            throw CoredataError.convertFailure(serviceName: .project, dataType: .project)
        }
        
        // construct data
        return ProjectDTO(
            userId: object.userId,
            projectId: object.projectId,
            title: object.title,
            status: object.status,            
            startAt: object.startedAt,
            deadline: object.deadline,
            todoRemain: todoRemain,
            todoCanRegist: object.dailyRegistedTodo,
            todoList: todoList,
            totalPeriod: totalPeriod,
            progressedPeriod: progressedPeriod,
            remainDays: remainDays
        )
    }
}

//MARK: Util

extension ProjectService {
    
    private func searchProjectIndex(with projectId: Int) async throws -> Int {
        guard let index = self.projectList.firstIndex(where: { $0.projectId == projectId }) else {
            print("[ProjectService] Failed to search project index at list")
            throw CoredataError.convertFailure(serviceName: .project, dataType: .project)
        }
        return index
    }
    
    private func searchTodoIndex(with projectIndex: Int, and todoId: Int) async throws -> Int {
        guard let todoIndex = projectList[projectIndex].todoList.firstIndex(where: { $0.todoId == todoId }) else {
            print("[ProjectService] Failed to search todo index at list")
            throw CoredataError.convertFailure(serviceName: .project, dataType: .project)
        }
        return todoIndex
    }
    
    private func fetchProjectObject(with projectId: Int) async -> ProjectObject? {
        do {
            return try projectCD.getObject(with: userId, and: projectId)
        } catch {
            print("[ProjectService] Failed to fetch project object at storage")
            return nil
        }
    }
}
