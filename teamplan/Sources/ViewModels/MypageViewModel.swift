//
//  MypageViewModel.swift
//  teamplan
//
//  Created by 크로스벨 on 5/1/24.
//  Copyright © 2024 team1os. All rights reserved.
//

import Foundation

final class MypageViewModel: ObservableObject {
    
    //MARK: Properties
    
    var userName: String
    @Published var dto: MypageDTO
    @Published var accomplishes: [Accomplishment]
    
    private let identifier: String
    private let service: MypageService
    
    //MARK: Initializer
    // prepare prepertise : UserDefault (userName / Identifier)
    init() {
        if let userDefault = UserDefaultManager.loadWith(),
           let identifier = userDefault.identifier,
           let userName = userDefault.userName {
            self.identifier = identifier
            self.userName = userName
        } else {
            self.identifier = "unknown"
            self.userName = "unknown"
            print("[MypageViewModel] Initialize Failed")
        }
        self.service = MypageService(userId: self.identifier)
        self.dto = MypageDTO()
        self.accomplishes = []
    }
    
    //MARK: Method
    
    func loadData() {
        Task {
            do {
                let dto = try service.getMypageDTO()
                DispatchQueue.main.async {
                    self.dto = dto
                    self.accomplishes = [
                        .init(accomplishTitle: AccomplishmentTitle.challenge.rawValue, accomplishCount: dto.completedChallenges),
                        .init(accomplishTitle: AccomplishmentTitle.project.rawValue, accomplishCount: dto.completedProjects),
                        .init(accomplishTitle: AccomplishmentTitle.todo.rawValue, accomplishCount: dto.completedTodos)
                    ]
                }
            } catch {
                print("Failed to load data: \(error)")
            }
        }
    }
    
    func performAction(menu: MypageMenu) throws {
        switch menu {
            
        case .logout:
            do {
                try service.logout()
            } catch let error as NSError {
                print(error)
            }
            
        case .withdraw:
            Task{ _ = await service.withdraw() }
 
        default:
            return
        }
    }
}

enum AccomplishmentTitle: String {
    case challenge = "완료 도전과제"
    case project = "완료한 목표"
    case todo = "완료한 할 일"
}
