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

    init() {
        let userDefaultManager = UserDefaultManager.loadWith(key: "user")
        let identifier = userDefaultManager?.identifier
        self.identifier = identifier ?? ""
        self.addSubscribers()
        Task {
            await self.getUserName()
        }
    }
    
    private func addSubscribers() {
        projectService.$projectList
            .receive(on: DispatchQueue.main)
            .sink { [weak self] projects in
                print("projects 개수: \(projects.count)")
                projects.forEach {
                    print("\($0.title): \($0.projectId), 시작날짜: \($0.startAt) ")
                }
                self?.projectList = projects
            }
            .store(in: &cancellables)
    }
    
    @MainActor
    private func getUserName() async {
        let userDefaultManager = UserDefaultManager.loadWith(key: "user")
        self.userName = userDefaultManager?.userName ?? "Unkown"
    }
    
    func addNewProject() {
        let start = self.startDate.futureDate(from: Date())
        let end = self.duration.futureDate(from: Date())
//        let newProject = ProjectSetDTO(title: projectName, startedAt: start, deadline: end)
//        try? projectService.setProject(with: newProject)
//        self.userProjects = try! projectService.getProjects()
//        self.projectStatus = try! projectService.getStatistics()
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
}
