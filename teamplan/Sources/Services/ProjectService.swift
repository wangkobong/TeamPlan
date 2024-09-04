//
//  ProjectService.swift
//  teamplan
//
//  Created by 크로스벨 on 6/9/24.
//  Copyright © 2024 team1os. All rights reserved.
//

import CoreData
import Foundation

final class ProjectService {
    
    // Published
    
    @Published var statDTO: StatDTO
    @Published var projectList: [ProjectDTO] = []
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
    func executor(action: ProjectServiceAction) -> Bool {
        let max = 3
        var retryCount = 1
        var isProcessComplete = false
        
        while retryCount <= max && !isProcessComplete {
            isProcessComplete = executeServiceAction(action)
            
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
    private func executeServiceAction(_ action: ProjectServiceAction) -> Bool {
        switch action {
        case .prepareService:
            return prepareServiceData()
        case .setNewProject(let newData, let setDate):
            return setNewProjectProcess(with: newData, on: setDate)
        case .renameProject(let projectId, let newTitle):
            return renameProjectProcess(with: projectId, and: newTitle)
        case .deleteProject(let projectId):
            return deleteProjectProcess(with: projectId)
        case .extendProject(let dto):
            return extendProjectProcess(with: dto)
        case .completeProject(let projectId, let completeDate):
            return completeProjectProcess(with: projectId, at: completeDate)
        case .setNewTodo(let projectId):
            return setNewTodoProcess(with: projectId)
        case .updateTodoStatus(let projectId, let todoId, let newStatus):
            return updateTodoStatusProcess(with: projectId, and: todoId, newStatus: newStatus)
        case .updateTodoDesc(let projectId, let todoId, let newDesc):
            return updateTodoDescProcess(with: projectId, and: todoId, newDesc: newDesc)
        }
    }
}

//MARK: Service - PrepareData

extension ProjectService {
    
    // executor
    private func prepareServiceData() -> Bool {
        let context = storageManager.context
        var results = [Bool]()
        
        context.performAndWait{
            results = [
                prepareStatData(with: context),
                prepareCoreValueData(with: context),
                prepareProjectData(with: context)
            ]
        }
        if results.allSatisfy({$0}) {
            self.projectRegistLimit = self.coreValue.projectRegistLimit
            return true
        } else {
            return false
        }
    }
    
    // fetch stat
    private func prepareStatData(with context: NSManagedObjectContext) -> Bool {
        do {
            if try statCD.getObject(context: context, userId: userId) {
                self.statDTO = StatDTO(with: statCD.object)
                return true
            } else {
                print("[ProjectService] Failed to fetch StatData")
                return false
            }
        } catch {
            print("[ProjectService] Failed to prepare StatData")
            return false
        }
    }
    
    // fetch corevalue
    private func prepareCoreValueData(with context: NSManagedObjectContext) -> Bool {
        do {
            if try coreValueCD.getObject(context: context, userId: userId) {
                self.coreValue = coreValueCD.object
                return true
            } else {
                print("[ProjectService] Failed to fetch CoreValue")
                return false
            }
        } catch {
            print("[ProjectService] Failed to prepare CoreValueData")
            return false
        }
    }
    
    // fetch project
    private func prepareProjectData(with context: NSManagedObjectContext) -> Bool {
        do {
            if try projectCD.getValidObjects(context: context, with: userId) {
                
                // fetch data
                for project in projectCD.objectList {
                    self.projectList.append(try convertExistObjectToDTO(with: project))
                }
                if self.projectList.isEmpty {
                    return true
                }
                
                // sort data
                let arraySize = self.projectList.count - 1
                for index in 0...arraySize {
                    sortTodoArray(with: index)
                }
                
                return true
            } else {
                print("[ProjectService] Failed to fetch ProjectData")
                return false
            }
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
    private func setNewProjectProcess(with newData: NewProjectDTO, on setDate: Date) -> Bool {
        let newProject = createNewProject(with: newData)

        guard updateObjectAboutProjectCreation(with: newProject) else {
            print("[ProjectService] Error detectred while set new project at storage")
            return false
        }
        
        guard updateDTOAboutProjectCreation(with: newProject) else {
            print("[ProjectService] Error detectred while set new project at dto")
            return false
        }
        return true
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

    // update: Object
    private func updateObjectAboutProjectCreation(with object: ProjectObject) -> Bool {
        let context = storageManager.context
        
        return context.performAndWait {
            do {
                guard projectCD.setObject(context: context, object: object) else {
                    print("[ProjectService] Failed to set new project data at storage context")
                    return false
                }
                
                var updated = StatUpdateDTO(
                    userId: userId,
                    newTotalRegistedProjects: self.statDTO.totalRegistedProjects + 1
                )
                
                guard try statCD.updateObject(context: context, dto: updated) else {
                    print("[ProjectService] Failed to detect StatObject update")
                    return false
                }
                
                guard storageManager.saveContext() else {
                    print("[ProjectService] Failed to apply new project data at storage")
                    return false
                }
                return true
                
            } catch {
                print("[ProjectService] set NewProject Process failed: \(error.localizedDescription)")
                return false
            }
        }
    }
    
    // update: DTO
    private func updateDTOAboutProjectCreation(with object: ProjectObject) -> Bool {
        do {
            self.statDTO.totalRegistedProjects += 1
            self.projectList.append(try convertNewObjectToDTO(with: object))
            return true
        } catch {
            print("[ProjectService] Failed to append project data at list")
            return false
        }
    }
}

//MARK: Project - Rename

extension ProjectService {
    
    // executor
    private func renameProjectProcess(with projectId: Int, and newTitle: String) -> Bool {
        do {
            // search project at list
            let index = try searchProjectIndex(with: projectId)
            
            // update object, then dto
            if updateObjectAboutRename(with: newTitle, and: index) {
                updateDTOAboutRename(with: newTitle, and: index)
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
    private func updateObjectAboutRename(with newTitle: String, and index: Int) -> Bool {
        let context = storageManager.context
        let updated = ProjectUpdateDTO(projectId: projectList[index].projectId, userId: userId, newTitle: newTitle)

        return context.performAndWait {
            do {
                guard try projectCD.updateObject(context: context, with: updated) else {
                    print("[ProjectService] ProjectObject change not detected")
                    return false
                }
                guard storageManager.saveContext() else {
                    print("[ProjectService] Failed to apply updated ProjectObject at storage")
                    return false
                }
                return true
                
            } catch {
                print("[ProjectService] Failed to get original projectObject: \(error.localizedDescription)")
                return false
            }
        }
    }
    
    // update: projectDTO
    private func updateDTOAboutRename(with newTitle: String, and index: Int) {
        projectList[index].title = newTitle
    }
}

//MARK: Project - Delete

extension ProjectService {
    
    // executor
    private func deleteProjectProcess(with projectId: Int) -> Bool {
        
        // delete object
        if updateObjectAboutDelete(with: projectId) {
            if updateDTOAboutdelete(with: projectId) {
                return true
            } else {
                print("[ProjectService] Failed to apply delete project in dto")
                return false
            }
        } else {
            print("[ProjectService] Failed to apply delete project in object")
            return false
        }
    }
    
    // update: projectObject
    private func updateObjectAboutDelete(with projectId: Int) -> Bool {
        let context = storageManager.context
        
        return context.performAndWait {
            do {
                try projectCD.deleteObject(context: context, with: userId, and: projectId)
                
                guard storageManager.saveContext() else {
                    print("[ProjectService] Failed to apply delete ProjectObject at storage")
                    return false
                }
                return true
                
            } catch {
                print("[ProjectService] Failed to fetch project entity: \(error.localizedDescription)")
                return false
            }
        }
    }
    
    // update: projectDTO
    private func updateDTOAboutdelete(with projectId: Int) -> Bool {
        do {
            let index = try searchProjectIndex(with: projectId)
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
    private func extendProjectProcess(with dto: ExtendProjectDTO) -> Bool {
        do {
            // get index
            let index = try searchProjectIndex(with: dto.projectId)
            
            // update object, then update dto
            guard updateObjectAboutExtend(with: dto.projectId, and: dto.newDeadline, index: index) else {
                return false
            }
            
            guard updateDTOAboutExtend(with: dto, and: index) else {
                return false
            }
            return true
            
        } catch {
            print("[ProjectService] Failed to search ProjectDTO index: \(error.localizedDescription)")
            return false
        }
    }
    
    // update: object
    private func updateObjectAboutExtend(with projectId: Int, and newDeadline: Date, index: Int) -> Bool {
        let context = storageManager.context
        
        return context.performAndWait{
            
            let previousObject: ProjectObject
            do {
                
                // fetch project object
                guard try projectCD.getSingleObject(context: context, with: userId, and: projectId) else {
                    print("[ProjectService] Failed to convert project object")
                    return false
                }
                previousObject = projectCD.object
                
                // update project object
                let projectUpdated = ProjectUpdateDTO(
                    projectId: projectId,
                    userId: userId,
                    newExtendedCount: previousObject.extendedCount + 1,
                    newDeadline: newDeadline)
  
                guard try projectCD.updateObject(context: context, with: projectUpdated) else {
                    print("[ProjectService] ProjectObject change not detected")
                    return false
                }

                // update stat object
                let statUpdated = StatUpdateDTO(
                    userId: userId,
                    newTotalExtendedProjects: self.statDTO.totalExtendedProjects + 1
                )

                guard try statCD.updateObject(context: context, dto: statUpdated) else {
                    print("[ProjectService] StatObject change not detected")
                    return false
                }
                
                // apply local storage
                guard storageManager.saveContext() else {
                    print("[ProjectService] Failed to apply extend ProjectObject at storage")
                    return false
                }
                return true
                
            } catch {
                print("[ProjectService] extend ProjectObject process failed: \(error.localizedDescription)")
                return false
            }
        }
    }
    
    // update: DTO
    private func updateDTOAboutExtend(with dto: ExtendProjectDTO, and index: Int) -> Bool {
        do {
            let today = Date()
            let newTotalPeriod = try util.calculateDatePeriod(with: projectList[index].startAt, and: dto.newDeadline)
            let newRemainDays = try util.calculateDatePeriod(with: today, and: dto.newDeadline)
            
            projectList[index].deadline = dto.newDeadline
            projectList[index].totalPeriod = newTotalPeriod
            projectList[index].remainDays = newRemainDays
            
            self.statDTO.totalExtendedProjects += 1
            return true
        } catch {
            print("[ProjectService] Failed to calculate new project period")
            return false
        }
    }
}

//MARK: Project - Complete

extension ProjectService {
    
    // shared
    func canCompleteProject(with projectId: Int) -> Bool {
        do {
            let index = try searchProjectIndex(with: projectId)
            return projectList[index].todoRemain == 0
        } catch {
            print("[ProjectService] Failed to search project index: \(error.localizedDescription)")
            return false
        }
    }
    
    // executor
    private func completeProjectProcess(with projectId: Int, at completeDate: Date) -> Bool {
        do {
            let index = try searchProjectIndex(with: projectId)
            
            guard updateObjectAboutComplete(with: projectId, at: completeDate, index: index) else {
                print("[ProjectService] Failed to apply complete object at storage")
                return false
            }
            updateDTOAboutComplete(with: index)
            return true
            
        } catch {
            print("[ProjectService] complete ProjectObject process failed: \(error.localizedDescription)")
            return false
        }
    }
    
    // update: Object
    private func updateObjectAboutComplete(with projectId: Int, at completeDate: Date, index: Int) -> Bool {
        let context = storageManager.context
        
        return context.performAndWait {
            do {
                // update project
                let projectUpdated = ProjectUpdateDTO(
                    projectId: projectId,
                    userId: userId,
                    newStatus: .finished,
                    newFinishedAt: completeDate
                )
                
                guard try projectCD.updateObject(context: context, with: projectUpdated) else {
                    print("[ProjectService] ProjectObject change not detected")
                    return false
                }
                
                // update stat
                let statUpdated = StatUpdateDTO(
                    userId: userId,
                    newTotalFinishedProjects: statDTO.totalFinishedProjects + 1,
                    newTotalFinishedTodos: projectList[index].todoList.count
                )
                
                guard try statCD.updateObject(context: context, dto: statUpdated) else {
                    print("[ProjectService] StatObject change not detected")
                    return false
                }
                
                // apply storage
                guard storageManager.saveContext() else {
                    print("[ProjectService] Failed to apply complete ProjectObject at storage")
                    return false
                }
                return true
                
            } catch {
                print("[ProjectService] complete ProjectObject process failed: \(error.localizedDescription)")
                return false
            }
        }
    }
    
    // update: projectDTO
    private func updateDTOAboutComplete(with index: Int) {
        self.projectList.remove(at: index)
        self.statDTO.totalFinishedProjects += 1
        self.statDTO.totalFinishedTodos += projectList[index].todoList.count
    }
}

//MARK: Project - Explode
// only update object
extension ProjectService {
    
    private func explodeProjectProcess(with projectId: Int, on explodeDate: Date) -> Bool {

        if updateObjectAboutExplode(with: projectId, on: explodeDate) {
            return true
        } else {
            return false
        }
    }
    
    // update: projectObject
    private func updateObjectAboutExplode(with projectId: Int, on explodeDate: Date) -> Bool {
        let context = storageManager.context
        
        return context.performAndWait {
            do {
                // update project
                let projectUpdated = ProjectUpdateDTO(
                    projectId: projectId,
                    userId: userId,
                    newStatus: .exploded,
                    newFinishedAt: explodeDate
                )
                
                guard try projectCD.updateObject(context: context, with: projectUpdated) else {
                    print("[ProjectService] ProjectObject change not detected")
                    return false
                }
                
                // update stat
                let statUpdated = StatUpdateDTO(
                    userId: userId,
                    newTotalFailedProjects: statDTO.totalFailedProjects + 1
                )
                
                guard try statCD.updateObject(context: context, dto: statUpdated) else {
                    print("[ProjectService] StatObject change not detected")
                    return false
                }
                
                // apply storage
                guard storageManager.saveContext() else {
                    print("[ProjectService] Failed to apply explode ProjectObject at storage")
                    return false
                }
                return true
                
            } catch {
                print("[ProjectService] explode ProjectObject process failed: \(error.localizedDescription)")
                return false
            }
        }
    }
}

//MARK: Todo - Create

extension ProjectService {
    
    // shared
    func canRegistNewTodo(with projectId: Int) -> Bool {
        do {
            let index = try searchProjectIndex(with: projectId)
            return projectList[index].todoCanRegist > 0
        } catch {
            print("[ProjectService] Failed to search project index")
            return false
        }
    }
    
    // executor
    private func setNewTodoProcess(with projectId: Int) -> Bool {
        do {
            let index = try searchProjectIndex(with: projectId)
            let newTodoId = projectList[index].todoList.count + 1
            let newTodo = createNewTodoObject(with: projectId, and: newTodoId, index: index)
            
            guard updateObjectAboutTodoCreation(with: newTodo) else {
                return false
            }
            updateDTOAboutTodoCreation(with: newTodo, and: index)
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

    // update object
    private func updateObjectAboutTodoCreation(with newTodo: TodoObject) -> Bool {
        let context = storageManager.context
        
        return context.performAndWait {
            do {
                // set todo
                guard try todoCD.setObject(context: context, with: newTodo) else {
                    print("[ProjectService] Failed to set new todo data at storage context")
                    return false
                }
                
                // update project
                guard try projectCD.getSingleObject(context: context, with: userId, and: newTodo.projectId) else {
                    print("[ProjectService] Failed to search project data")
                    return false
                }
                let projectData = projectCD.object
                var updatedProject = ProjectUpdateDTO(
                    projectId: newTodo.projectId,
                    userId: userId,
                    newTotalRegistedTodo: projectData.totalRegistedTodo + 1,
                    newDailyRegistedTodo: projectData.dailyRegistedTodo - 1
                )
                guard try projectCD.updateObject(context: context, with: updatedProject) else {
                    print("[ProjectService] ProjectObject change not detected")
                    return false
                }
                
                // update stat
                print(statDTO)
                var updatedStat = StatUpdateDTO(
                    userId: userId,
                    newTotalRegistedTodos: statDTO.totalRegistedTodos + 1
                )
                guard try statCD.updateObject(context: context, dto: updatedStat) else {
                    print("[ProjectService] StatObject change not detected")
                    return false
                }
                
                // apply storage
                guard storageManager.saveContext() else {
                    print("[ProjectService] Failed to apply new todo at storage")
                    return false
                }
                return true
                
            } catch {
                print("[ProjectService] set NewTodo process failed: \(error.localizedDescription)")
                return false
            }
        }
    }

    // update DTO
    private func updateDTOAboutTodoCreation(with newTodo: TodoObject, and projectIndex: Int) {
        let todoDTO = TodoDTO(with: newTodo)
        self.statDTO.totalRegistedTodos += 1
        self.projectList[projectIndex].todoList.insert(todoDTO, at: 0)
        self.projectList[projectIndex].todoCanRegist -= 1
        self.projectList[projectIndex].todoRemain += 1
    }
}

//MARK: Todo - UpdateStatus

extension ProjectService {
    
    // executor
    private func updateTodoStatusProcess(with projectId: Int, and todoId: Int, newStatus: TodoStatus) -> Bool {
        do {
            let projectIndex = try searchProjectIndex(with: projectId)
            let todoIndex = try searchTodoIndex(with: projectIndex, and: todoId)
            
            guard updateObjectAboutTodoUpdate(with: projectId, and: todoId, to: newStatus) else {
                return false
            }
            updateDTOAboutTodoUpdate(with: projectIndex, and: todoIndex, newStatus: newStatus)
            return true
            
        } catch {
            print("[ProjectService] Failed to search index for project: [\(projectId)]")
            return false
        }
    }

    // update: Object
    private func updateObjectAboutTodoUpdate(with projectId: Int, and todoId: Int, to newStatus: TodoStatus) -> Bool {
        let context = storageManager.context
        
        return context.performAndWait {
            do {
                // update todo
                let updatedTodo = TodoUpdateDTO(
                    projectId: projectId,
                    todoId: todoId,
                    userId: userId,
                    newStatus: newStatus
                )
                guard try todoCD.updateObject(context: context, updated: updatedTodo) else {
                    print("[ProjectService] TodoObject change not detected: [\(todoId)] in project: [\(projectId)]")
                    return false
                }
                
                // update stat & project
                guard try projectCD.getSingleObject(context: context, with: userId, and: projectId) else {
                    print("[ProjectService] Failed to search project data")
                    return false
                }
                let projectData = projectCD.object
                var updatedStat = StatUpdateDTO(userId: userId)
                var updatedProject = ProjectUpdateDTO(projectId: projectId, userId: userId)
                
                switch newStatus {
                case .finish:
                    updatedStat.newTotalFinishedTodos = statDTO.totalFinishedTodos + 1
                    updatedProject.newFinishedTodo = projectData.finishedTodo + 1
                case .ongoing:
                    updatedStat.newTotalFinishedTodos = statDTO.totalFinishedTodos - 1
                    updatedProject.newFinishedTodo = projectData.finishedTodo - 1
                }
                guard try statCD.updateObject(context: context, dto: updatedStat) else {
                    print("[ProjectService] TodoObject change not applied at statData")
                    return false
                }
                guard try projectCD.updateObject(context: context, with: updatedProject) else {
                    print("[ProjectService] TodoObject change not detected in project: [\(projectId)]")
                    return false
                }
                
                // apply storage
                guard storageManager.saveContext() else {
                    print("[ProjectService] Failed to apply updated TodoObject at storage: [\(todoId)] in project: [\(projectId)]")
                    return false
                }
                return true
                
            } catch {
                print("[ProjectService] update todo status process failed: \(error.localizedDescription)")
                return false
            }
        }
    }

    // update: DTO
    private func updateDTOAboutTodoUpdate(with projectIndex: Int, and todoIndex: Int, newStatus: TodoStatus) {
        switch newStatus {
        case .finish:
            self.statDTO.totalFinishedTodos += 1
            self.projectList[projectIndex].todoRemain -= 1
        case .ongoing:
            self.statDTO.totalFinishedTodos -= 1
            self.projectList[projectIndex].todoRemain += 1
        }
        self.projectList[projectIndex].todoList[todoIndex].status = newStatus
        sortTodoArray(with: projectIndex)
    }
}

//MARK: Todo - UpdateDesc

extension ProjectService {
    private func updateTodoDescProcess(with projectId: Int, and todoId: Int, newDesc: String) -> Bool {
        do {
            let projectIndex = try searchProjectIndex(with: projectId)
            let todoIndex = try searchTodoIndex(with: projectIndex, and: todoId)
            
            guard updateObjectAboutTodoDesc(with: projectId, and: todoId, newDesc: newDesc) else {
                return false
            }
            updateDTOAboutTodoDesc(with: projectIndex, and: todoIndex, newDesc: newDesc)
            return true
            
        } catch {
            print("[ProjectService] Failed to search index for project: [\(projectId)]")
            return false
        }
    }
    
    // update object
    private func updateObjectAboutTodoDesc(with projectId: Int, and todoId: Int, newDesc: String) -> Bool {
        let context = storageManager.context
        
        return context.performAndWait {
            do {
                let updated = TodoUpdateDTO(projectId: projectId, todoId: todoId, userId: userId, newDesc: newDesc)
                guard try todoCD.updateObject(context: context, updated: updated) else {
                    print("[ProjectService] TodoObject change not detected")
                    return false
                }
                guard storageManager.saveContext() else {
                    print("[ProjectService] Failed to apply updated TodoObject at storage")
                    return false
                }
                return true
                
            } catch {
                print("[ProjectService] update todo desc process failed: \(error.localizedDescription)")
                return false
            }
        }
    }
    
    // update dto
    private func updateDTOAboutTodoDesc(with projectIndex: Int, and todoIndex: Int, newDesc: String) {
        self.projectList[projectIndex].todoList[todoIndex].desc = newDesc
    }
}

//MARK: Util

extension ProjectService {
    
    private func searchProjectIndex(with projectId: Int) throws -> Int {
        guard let index = self.projectList.firstIndex(where: { $0.projectId == projectId }) else {
            print("[ProjectService] Failed to search project index at list")
            throw CoredataError.convertFailure(serviceName: .project, dataType: .project)
        }
        return index
    }
    
    private func searchTodoIndex(with projectIndex: Int, and todoId: Int) throws -> Int {
        guard let todoIndex = projectList[projectIndex].todoList.firstIndex(where: { $0.todoId == todoId }) else {
            print("[ProjectService] Failed to search todo index at list")
            throw CoredataError.convertFailure(serviceName: .project, dataType: .project)
        }
        return todoIndex
    }
    
    private func sortTodoArray(with projectIndex: Int) {
        if  self.projectList[projectIndex].todoList.isEmpty {
            return
        }
        let sortedList = self.projectList[projectIndex].todoList.sorted{ (leftValue, rightValue) -> Bool in
            if leftValue.status == rightValue.status {
                return leftValue.todoId > rightValue.todoId
            }
            return leftValue.status.rawValue < rightValue.status.rawValue
        }
        self.projectList[projectIndex].todoList  = sortedList
    }
}

//MARK: DTO

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
    
    private func convertNewObjectToDTO(with object: ProjectObject) throws -> ProjectDTO {
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
    
    private func convertExistObjectToDTO(with object: ProjectObject) throws -> ProjectDTO {
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


