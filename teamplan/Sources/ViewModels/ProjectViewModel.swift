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
    
    var projects: [ProjectModel] = [
        ProjectModel(name: "막걸리 브랜딩 프로젝트",
                     startDate: 10,
                     endDate: 5,
                     toDos:  [
                        ToDo(name: "요구사항 정의", isDone: true),
                        ToDo(name: "브랜딩 3개 거래처 수정", isDone: false),
                        ToDo(name: "홈 화면 UI elwkdls", isDone: false),
                        ToDo(name: "깃허브 작업 깃허브 작업 깃허브 작업 깃허브 작업 깃허브 작업", isDone: false),
                        ToDo(name: "서비스 트러블 슈팅 정리", isDone: true),
                     ]),
        ProjectModel(name: "소주 브랜딩 프로젝트",
                     startDate: 10,
                     endDate: 5,
                     toDos:  [
                        ToDo(name: "요구사항 정의", isDone: false),
                        ToDo(name: "브랜딩 3개 거래처 수정", isDone: false),
                        ToDo(name: "홈 화면 UI elwkdls", isDone: false),
                        ToDo(name: "깃허브 작업 깃허브 작업 깃허브 작업 깃허브 작업 깃허브 작업", isDone: false),
                        ToDo(name: "서비스 트러블 슈팅 정리", isDone: false),
                     ]),
        ProjectModel(name: "맥주 브랜딩 프로젝트",
                     startDate: 10,
                     endDate: 5,
                     toDos:  [
                        ToDo(name: "요구사항 정의", isDone: false),
                        ToDo(name: "브랜딩 3개 거래처 수정", isDone: false),
                        ToDo(name: "홈 화면 UI elwkdls", isDone: false),
                        ToDo(name: "깃허브 작업 깃허브 작업 깃허브 작업 깃허브 작업 깃허브 작업", isDone: false),
                        ToDo(name: "서비스 트러블 슈팅 정리", isDone: false),
                     ]),
        ProjectModel(name: "위스키 브랜딩 프로젝트",
                     startDate: 10,
                     endDate: 5,
                     toDos:  [
                        ToDo(name: "요구사항 정의", isDone: false),
                        ToDo(name: "브랜딩 3개 거래처 수정", isDone: false),
                        ToDo(name: "홈 화면 UI elwkdls", isDone: false),
                        ToDo(name: "깃허브 작업 깃허브 작업 깃허브 작업 깃허브 작업 깃허브 작업", isDone: false),
                        ToDo(name: "서비스 트러블 슈팅 정리", isDone: false),
                     ]),
        ProjectModel(name: "투두없는 프로젝트",
                     startDate: 10,
                     endDate: 5,
                     toDos:  [])
    ]

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
        
    }
    
    @MainActor
    private func getUserName() async {
        let userDefaultManager = UserDefaultManager.loadWith(key: "user")
        self.userName = userDefaultManager?.userName ?? "Unkown"
    }
}
