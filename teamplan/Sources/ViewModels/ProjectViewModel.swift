//
//  ProjectViewModel.swift
//  teamplan
//
//  Created by sungyeon on 2024/02/01.
//  Copyright © 2024 team1os. All rights reserved.
//

import Foundation
import Combine

final class ProjectViewModel: ObservableObject {

    
    @Published var userName: String = ""
    @Published var statData: StatDTO = StatDTO()
    @Published var projectList: [ProjectDTO] = []
    
    // AddProjectView에 필요한 프로퍼티
    @Published var projectName: String = ""
    @Published var startDate: StartDateSelection = .none
    @Published var duration: DurationSelection = .none
    
    // ExtendProjectView에 필요한 프로퍼티
    @Published var waterDrop: [String] = []
    
    var projectRegistLimit: Int
    
    private let identifier: String
    private var isViewModelReady: Bool
    private var service: ProjectService
    
    @MainActor
    init() {
        let volt = VoltManager.shared
        if let identifier = volt.getUserId(),
           let userName = volt.getUserName() {
            self.identifier = identifier
            self.userName = userName
            
        } else {
            print("[ProjectViewModel] ViewModel Initialize Failed")
            self.identifier = "unknown"
            self.userName = "unknown"
        }
        self.service = ProjectService(userId: identifier)
        self.projectRegistLimit = 0
        self.isViewModelReady = false
    }
    
    func prepareData() async -> Bool {
        if service.executor(action: .prepareService) {
            await Task {
                await updateStatData()
                await updateProjectList()
            }.value
            
            self.projectRegistLimit = service.projectRegistLimit
            self.createWaterDropArray(upTo: statData.drop)
            self.isViewModelReady = true
            return true
        } else {
            print("[ProjectViewModel] Failed to prepare data")
            return false
        }
    }
}

extension ProjectViewModel {
    
    // MARK: Project - Add
    
    func addNewProject() -> Bool {
        guard service.canRegistNewProject() else {
            return false
        }
        let addDate = Date()
        let dto = prepareNewDTO(at: addDate)
        return executeAddProcess(with: dto, at: addDate)
    }
    
    private func prepareNewDTO(at addDate: Date) -> NewProjectDTO {
        let addDate = Date()
        return NewProjectDTO(
            title: self.projectName,
            startAt: self.startDate.futureDate(from: addDate),
            deadline: self.duration.futureDate(from: addDate),
            setDate: addDate
        )
    }
    
    private func executeAddProcess(with newDTO: NewProjectDTO, at addDate: Date) -> Bool {
        let result = service.executor(action:
                .setNewProject(newData: newDTO, setDate: addDate)
        )
        if result {
            Task {
                await updateStatData()
                await updateProjectList()
                await initAddingProjectProperty()
            }
            print("[ProjectViewModel] Successfully execute add project")
            return true
        } else {
            print("[ProjectViewModel] Failed to execute add project")
            return false
        }
    }
    
    // MARK: Project - Delete
    
    func deleteProject(projectId: Int) -> Bool {
        let result = service.executor(action:
                .deleteProject(projectId: projectId)
        )
        if result {
            Task { await updateProjectList() }
            return true
        } else {
            print("[ProjectViewModel] Failed to execute delete project")
            return false
        }
    }
    
    // MARK: Project - Extend
    
    func extendProjectDay(projectId: Int, usedDrop: Int? = nil, newDeadline: Date? = nil, newTitle: String? = nil) -> Bool {
        
        var actionResult: Bool = false
        
        if let newTitle = newTitle, usedDrop == nil, newDeadline == nil {
            actionResult = executeRenameProcess(with: projectId, and: newTitle)
            
        } else if newTitle == nil, let usedDrop = usedDrop, let newDeadline = newDeadline {
            actionResult = executeExtendProcess(with: projectId, newDeadline: newDeadline, usedDrop: usedDrop)
            
        } else if let newTitle = newTitle, let usedDrop = usedDrop, let newDeadline = newDeadline {
            actionResult = executeRenameAndExtendProcess(with: projectId, newDeadline: newDeadline, usedDrop: usedDrop, newTitle: newTitle)
            
        } else {
            print("[ProjectViewModel] Alert! Unknown extend type detected!")
            return false
        }
        return actionResult
    }
    
    private func executeRenameProcess(with projectId: Int, and newTitle: String) -> Bool {
        let result = service.executor(action:
                .renameProject(projectId: projectId, newTitle: newTitle)
        )
        if result {
            Task { await updateProjectList() }
            return true
            
        } else {
            print("[ProjectViewModel] Failed to execute rename project")
            return false
        }
    }
    
    private func executeExtendProcess(with projectId: Int, newDeadline: Date, usedDrop: Int) -> Bool {
        
        let dto = ExtendProjectDTO(projectId: projectId, usedDrop: usedDrop, newDeadline: newDeadline)
        let result = service.executor(action: .extendProject(dto: dto))
        
        if result {
            Task {
                await updateStatData()
                await updateProjectList()
            }
            return true
            
        } else {
            print("[ProjectViewModel] Failed to execute extend project")
            return false
        }
    }
    
    private func executeRenameAndExtendProcess(with projectId: Int, newDeadline: Date, usedDrop: Int, newTitle: String) -> Bool {
        
        let dto = ExtendProjectDTO(projectId: projectId, usedDrop: usedDrop, newDeadline: newDeadline)
        let isRenamed = service.executor(action: .renameProject(projectId: projectId, newTitle: newTitle))
        let isExtended = service.executor(action: .extendProject(dto: dto))
        
        if isRenamed && isExtended {
            Task {
                await updateStatData()
                await updateProjectList()
            }
            return true
            
        } else {
            print("[ProjectViewModel] Failed to execute rename and extend project")
            return false
        }
    }
    
    // MARK: Project - Complete
    
    func completeProject(with projectId: Int) async -> Bool {
        
        // inspection
        guard service.canCompleteProject(with: projectId) else {
            return false
        }
        
        // process
        let completeDate = Date()
        if service.executor(action: .completeProject(projectId: projectId, completeDate: completeDate)) {
            Task {
                await updateStatData()
                await updateProjectList()
            }
            return true
            
        } else {
            print("[ProjectViewModel] Failed to execute compelete project")
            return false
        }
    }
    
    // MARK: Todo - Add
    
    func addNewTodo(projectId: Int) -> Bool {
        
        // process
        if service.executor(action: .setNewTodo(projectId: projectId)) {
            
            guard let indexList = searchProjectIndex(with: projectId) else {
                return false
            }
            Task {
                await updateStatData()
                await updateProject(viewModelIndex: indexList.viewModelIndex, serviceIndex: indexList.serviceIndex)
            }
            return true
            
        } else {
            print("[ProjectViewModel] Failed to execute add todo")
            return false
        }
    }
    
    // MARK: Todo - Update Desc
    
    func updateTodoDescription(with projectId: Int, todoId: Int, newDesc: String) -> Bool {
        
        if service.executor(action: .updateTodoDesc(projectId: projectId, todoId: todoId, newDesc: newDesc)) {
            
            guard let indexList = searchProjectIndex(with: projectId) else {
                return false
            }
            Task {
                await updateProject(viewModelIndex: indexList.viewModelIndex, serviceIndex: indexList.serviceIndex)
            }
            return true
            
        } else {
            print("[ProjectViewModel] Failed to execute update todo desc")
            return false
        }
    }
    
    // MARK: Todo - Update Status
    
    func toggleToDoStatus(with projectId: Int, todoId: Int, newStatus: TodoStatus) -> Bool {
        
        if service.executor(action: .updateTodoStatus(projectId: projectId, todoId: todoId, newStatus: newStatus)) {
            
            guard let indexList = searchProjectIndex(with: projectId) else {
                return false
            }
            Task {
                await updateProject(viewModelIndex: indexList.viewModelIndex, serviceIndex: indexList.serviceIndex)
            }
            return true
            
        } else {
            print("[ProjectViewModel] Failed to execute update todo status")
            return false
        }
    }
    
    // MARK: Util
    
    func createWaterDropArray(upTo number: Int) {
        guard number > 0 else { return }
        let waterDrops = Array(1...number)
        self.waterDrop = waterDrops.map { "\($0)일 연장하기" }
    }
    
    private func searchProjectIndex(with projectId: Int) -> (serviceIndex: Int, viewModelIndex: Int)? {
        if let serviceIndex = service.projectList.firstIndex(where: { $0.projectId == projectId }),
           let viewModelIndex = self.projectList.firstIndex(where: { $0.projectId == projectId }) {
            return (serviceIndex, viewModelIndex)
        } else {
            print("[ProjectViewModel] Failed to search project index")
            return nil
        }
    }
}

// MARK: Properties Update

extension ProjectViewModel {
    
    @MainActor
    func initAddingProjectProperty() {
        self.startDate = .none
        self.duration = .none
        self.projectName = ""
    }
    
    @MainActor
    func updateStatData() {
        self.statData = self.service.statDTO
    }
    
    @MainActor
    func updateProjectList() {
        self.projectList = self.service.projectList
    }
    
    @MainActor
    private func updateProject(viewModelIndex: Int, serviceIndex: Int) {
        self.projectList[viewModelIndex] = self.service.projectList[serviceIndex]
    }
}
