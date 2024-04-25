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
    
    lazy var projectService = ProjectService(userId: self.identifier)
    
    @Published var projectList: [ProjectDTO] = []
    
    // AddProjectView에 필요한 프로퍼티
    @Published var projectName: String = ""
    @Published var startDate: StartDateSelection = .none
    @Published var duration: DurationSelection = .none
    // ExtendProjectView에 필요한 프로퍼티
    @Published var waterDrop: [String] = []

    init() {
        let userDefaultManager = UserDefaultManager.loadWith(key: "user")
        let identifier = userDefaultManager?.identifier
        self.identifier = identifier ?? ""
        self.addSubscribers()
        Task {
            await self.getUserName()
        }
        self.createWaterDropArray(upTo: projectService.statData.drop)
    }
    
    private func addSubscribers() {
        projectService.$projectList
            .receive(on: DispatchQueue.main)
            .sink { [weak self] projects in
                self?.projectList = projects
            }
            .store(in: &cancellables)
    }
    
    @MainActor
    private func getUserName() async {
        let userDefaultManager = UserDefaultManager.loadWith(key: "user")
        self.userName = userDefaultManager?.userName ?? "Unkown"
    }
    
    // MARK: - projects METHOD
    func addNewProject() {
        let start = self.startDate.futureDate(from: Date())
        let end = self.duration.futureDate(from: Date())
        do {
            try projectService.setNewProject(title: projectName, startAt: start, deadline: end)
        } catch {
            print("error: \(error)")
        }
        self.startDate = .none
        self.duration = .none
        self.projectName = ""
        getProjects()
    }
    
    func getProjects() {
        do {
            try projectService.prepareService()
        } catch {
            print("error: \(error)")
        }
    }
    
    func deleteProject(projectId: Int) {
        do {
            try projectService.deleteProject(projectId: projectId)
        } catch {
            print("error: \(error)")
        }
    }
    
    func initAddingProjectProperty() {
        self.startDate = .none
        self.duration = .none
        self.projectName = ""
    }
    
    
    // MARK: - ToDo METHOD
    func addNewTodo(projectId: Int) {
        
        if projectService.canRegistNewProject() {
            
        } else {
            
        }
        
        do {
            try projectService.setNewTodo(projectId: projectId)
        } catch {
            print("error: \(error)")
        }
    }
    
    func updateTodoDescription(with projectId: Int, todoId: Int, newDesc: String) {
        do {
            try projectService.updateTodoDesc(with: projectId, todoId: todoId, newDesc: newDesc)
        } catch {
            
        }
    }
    
    func toggleToDoStatus(with projectId: Int, todoId: Int, newStatus: TodoStatus) {
        do {
            try projectService.updateTodoStatus(with: projectId, todoId: todoId, newStatus: newStatus)
        } catch {
            
        }
    }
    
    func completeProject(with projectId: Int) async {
        do {
            try projectService.completeProject(projectId: projectId)
        } catch {
            print("error: \(error)")
        }
    }
    
    func createWaterDropArray(upTo number: Int) {
        guard number > 0 else {
            return
        }
        let waterDrops = Array(1...number)
        self.waterDrop = waterDrops.map { String($0) + "일 연장하기" }
    }
    
    func extendProjectDay(projectId: Int, usedDrop: Int, newDeadline: Date, newTitle: String) {
        do {
            try projectService.extendProject(projectId: projectId, usedDrop: usedDrop, newDeadline: newDeadline, newTitle: newTitle)
        } catch {
            print("error: \(error)")
        }
    }
    
}
