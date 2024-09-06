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
    let identifier: String
    
    private var cancellables = Set<AnyCancellable>()
    private var isSubscribersAdded = false
    
    var service: ProjectService
    var projectRegistLimit: Int
    
    @Published var statData: StatDTO = StatDTO()
    @Published var projectList: [ProjectDTO] = []
    
    @Published var isViewModelReady: Bool = false
    @Published var isReInitiNeed: Bool = false     // need to re-initilize viewModel
    @Published var isProejctCanAdd: Bool = false
    @Published var isProejctCanComplete: Bool = false
    @Published var isProjectRemoved: Bool = false
    @Published var isTodoCanAdd: Bool = false
    
    // AddProjectView에 필요한 프로퍼티
    @Published var projectName: String = ""
    @Published var startDate: StartDateSelection = .none
    @Published var duration: DurationSelection = .none
    // ExtendProjectView에 필요한 프로퍼티
    @Published var waterDrop: [String] = []
    
    @MainActor
    init() {
        let volt = VoltManager.shared
        if let identifier = volt.getUserId(),
           let userName = volt.getUserName() {
            self.identifier = identifier
            self.userName = userName
            
        } else {
            self.identifier = "unknown"
            self.userName = "unknown"
        }
        self.service = ProjectService(userId: identifier)
        self.projectRegistLimit = 0
        
        self.prepareData()
        self.createWaterDropArray(upTo: statData.drop)
    }
    
    private func prepareData() {
        Task {
            let result = service.executor(action: .prepareService)
            
            if result {
                await updateProjectList()
                await updateStatData()
                self.projectRegistLimit = service.projectRegistLimit
                self.isViewModelReady = true
            } else {
                print("[ProjectViewModel] Failed to prepare data")
                self.isViewModelReady = false
            }
        }
    }
}

extension ProjectViewModel {
    
    // MARK: Project - Add
    
    func addNewProject() {
        guard service.canRegistNewProject() else {
            self.isProejctCanAdd = false
            return
        }
        
        let addDate = Date()
        let dto = prepareNewDTO(at: addDate)
        executeAddProcess(with: dto, at: addDate)
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
    
    private func executeAddProcess(with newDTO: NewProjectDTO, at addDate: Date) {
        Task {
            let result = service.executor(action:
                    .setNewProject(newData: newDTO, setDate: addDate)
            )
            if result {
                await updateStatData()
                await updateProjectList()
                await initAddingProjectProperty()
                print("[ProjectViewModel] Successfully execute add project")
            } else {
                print("[ProjectViewModel] Failed to execute add project")
                self.isReInitiNeed = true
            }
        }
    }
    
    // MARK: Project - Delete
    
    func deleteProject(projectId: Int) {
        Task {
            let result = service.executor(action:
                    .deleteProject(projectId: projectId)
            )
            if result {
                await updateArrayRemovedStatus()
            } else {
                print("[ProjectViewModel] Failed to execute delete project")
                self.isReInitiNeed = true
            }
        }
    }
    
    // MARK: Project - Extend
    
    func extendProjectDay(projectId: Int, usedDrop: Int? = nil, newDeadline: Date? = nil, newTitle: String? = nil) {
        
        if let newTitle = newTitle, usedDrop == nil, newDeadline == nil {
            executeRenameProcess(with: projectId, and: newTitle)
            
        } else if newTitle == nil, let usedDrop = usedDrop, let newDeadline = newDeadline {
            executeExtendProcess(with: projectId, newDeadline: newDeadline, usedDrop: usedDrop)
            
        } else if let newTitle = newTitle, let usedDrop = usedDrop, let newDeadline = newDeadline {
            executeRenameAndExtendProcess(with: projectId, newDeadline: newDeadline, usedDrop: usedDrop, newTitle: newTitle)
            
        } else {
            print("[ProjectViewModel] Alert! Unknown extend type detected!")
            self.isReInitiNeed = true
            return
        }
    }
    
    private func executeRenameProcess(with projectId: Int, and newTitle: String) {
        Task {
            let result = service.executor(action:
                    .renameProject(projectId: projectId, newTitle: newTitle)
            )
            if result {
                await updateProjectDTO(with: projectId)
            } else {
                print("[ProjectViewModel] Failed to execute rename project")
                self.isReInitiNeed = true
            }
        }
    }
    
    private func executeExtendProcess(with projectId: Int, newDeadline: Date, usedDrop: Int) {
        let dto = ExtendProjectDTO(projectId: projectId, usedDrop: usedDrop, newDeadline: newDeadline)
        
        Task {
            let result = service.executor(action:
                    .extendProject(dto: dto)
            )
            if result {
                await updateStatData()
                await updateProjectDTO(with: projectId)
            } else {
                print("[ProjectViewModel] Failed to execute extend project")
                self.isReInitiNeed = true
            }
        }
    }
    
    private func executeRenameAndExtendProcess(with projectId: Int, newDeadline: Date, usedDrop: Int, newTitle: String) {
        let dto = ExtendProjectDTO(projectId: projectId, usedDrop: usedDrop, newDeadline: newDeadline)
        
        Task {
            async let isRenamed = service.executor(action:
                    .renameProject(projectId: projectId, newTitle: newTitle)
            )
            async let isExtended = service.executor(action:
                    .extendProject(dto: dto)
            )
            let results = await [isRenamed, isExtended]
            
            if results.allSatisfy({ $0 }){
                await updateStatData()
                await updateProjectDTO(with: projectId)
            } else {
                print("[ProjectViewModel] Failed to execute rename and extend project")
                self.isReInitiNeed = true
            }
        }
    }
    
    // MARK: Project - Complete
    
    func completeProject(with projectId: Int) async {
        guard service.canCompleteProject(with: projectId) else {
            self.isProejctCanComplete = false
            return
        }
        await executeCompleteProcess(with: projectId)
        print("[ProjectViewModel] Successfully execute compelete project")
    }
    
    private func executeCompleteProcess(with projectId: Int) async {
        let completeDate = Date()
        let result = service.executor(action:
                .completeProject(projectId: projectId, completeDate: completeDate)
        )
        if result {
            await updateStatData()
            await updateArrayRemovedStatus()
        } else {
            print("[ProjectViewModel] Failed to execute compelete project")
            self.isReInitiNeed = true
        }
    }
    
    // MARK: Todo - Add
    
    func addNewTodo(projectId: Int) {
        Task {
            guard service.canRegistNewTodo(with: projectId) else {
                print("[ProjectViewModel] Todo regist limit detected")
                self.isTodoCanAdd = false
                return
            }
            await executeAddTodoProcess(with: projectId)
        }
    }
    
    private func executeAddTodoProcess(with projectId: Int) async {
        let result = service.executor(
            action: .setNewTodo(projectId: projectId)
        )
        if result {
            await updateStatData()
            await updateProjectDTO(with: projectId)
            await updateTodoList(with: projectId)
        } else {
            print("[ProjectViewModel] Failed to execute add todo")
            self.isReInitiNeed = true
        }
    }
    
    // MARK: Todo - Update Desc
    
    func updateTodoDescription(with projectId: Int, todoId: Int, newDesc: String) {
        Task {
            let result = service.executor(action:
                    .updateTodoDesc(projectId: projectId, todoId: todoId, newDesc: newDesc)
            )
            if result {
                await updateTodoDTO(with: projectId, and: todoId)
            } else {
                print("[ProjectViewModel] Failed to execute update todo desc")
                self.isReInitiNeed = true
            }
        }
    }
    
    // MARK: Todo - Update Status
    
    func toggleToDoStatus(with projectId: Int, todoId: Int, newStatus: TodoStatus) {
        Task {
            let result = service.executor(action:
                    .updateTodoStatus(projectId: projectId, todoId: todoId, newStatus: newStatus)
            )
            if result {
                await updateProjectDTO(with: projectId)
                await updateTodoDTO(with: projectId, and: todoId)
            } else {
                print("[ProjectViewModel] Failed to execute update todo status")
                self.isReInitiNeed = true
            }
        }
    }
    
    // MARK: Util
    
    func createWaterDropArray(upTo number: Int) {
        guard number > 0 else { return }
        let waterDrops = Array(1...number)
        self.waterDrop = waterDrops.map { "\($0)일 연장하기" }
    }
}

// MARK: Main Actor

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
    private func updateArrayRemovedStatus() {
        self.isProjectRemoved = true
    }
    
    @MainActor
    private func updateTodoList(with projectId: Int) {
        if let serviceIndex = service.projectList.firstIndex(where: { $0.projectId == projectId }),
           let index = projectList.firstIndex(where: { $0.projectId == projectId }) {
            projectList[index].todoList = service.projectList[serviceIndex].todoList
        } else {
            print("[ProjectViewModel] Failed to search project index")
            self.isReInitiNeed = true
        }
    }
    
    @MainActor
    private func updateProjectDTO(with projectId: Int) {
        if let serviceIndex = service.projectList.firstIndex(where: { $0.projectId == projectId }),
           let index = projectList.firstIndex(where: { $0.projectId == projectId }) {
            projectList[index] = service.projectList[serviceIndex]
            print("[ProjectViewModel] Successfully update projectDTO")
        } else {
            print("[ProjectViewModel] Failed to search project index")
            self.isReInitiNeed = true
        }
    }
    
    @MainActor
    private func updateTodoDTO(with projectId: Int, and todoId: Int) {
        guard
            let projectIndex = projectList.firstIndex(where: { $0.projectId == projectId }),
            let serviceProjectIndex = service.projectList.firstIndex(where: { $0.projectId == projectId }),
            let todoIndex = projectList[projectIndex].todoList.firstIndex(where: { $0.todoId == todoId }),
            let serviceTodoIndex = service.projectList[serviceProjectIndex].todoList.firstIndex(where: { $0.todoId == todoId })
        else {
            print("[ProjectViewModel] Failed to search project todo index")
            self.isReInitiNeed = true
            return
        }
        projectList[projectIndex].todoList[todoIndex] = service.projectList[serviceProjectIndex].todoList[serviceTodoIndex]
        print("[ProjectViewModel] Successfully update todoDTO")
    }
}

/*
private func addSubscribers() {
    service.$projectList
        .receive(on: DispatchQueue.main)
        .sink { [weak self] projects in
            self?.projectList = projects
        }
        .store(in: &cancellables)

    service.$statDTO
        .receive(on: DispatchQueue.main)
        .sink { [weak self] statData in
            self?.statData = statData
        }
        .store(in: &cancellables)
}
 */
