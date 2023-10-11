//
//  NotificationViewModel.swift
//  teamplan
//
//  Created by sungyeon kim on 2023/08/12.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation
import Combine
import KeychainSwift

final class NotificationViewModel: ObservableObject {
    
    @Published var notiSections: [NotificationSection] = []
    
    @Published var allNotiList: [NotificationModel] = []
    @Published var projectNotiList: [NotificationModel] = []
    @Published var todoNotiList: [NotificationModel] = []
    @Published var challengeNotiList: [NotificationModel] = []
    @Published var noticeNotiList: [NotificationModel] = []
    
    @Published var filteredNotiList: [NotificationModel] = []
    
    private let notificationDataService = NotificationDataService()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        self.addSubscribers()
    }
    
    private func addSubscribers() {
        
        notificationDataService.$projectNotiList
            .sink { [weak self] projectNotiList in
                self?.projectNotiList = projectNotiList
            }
            .store(in: &cancellables)
        
        notificationDataService.$todoNotiList
            .sink { [weak self] todoNotiList in
                self?.todoNotiList = todoNotiList
            }
            .store(in: &cancellables)
        
        notificationDataService.$challengeNotiList
            .sink { [weak self] challengeNotiList in
                self?.challengeNotiList = challengeNotiList
            }
            .store(in: &cancellables)
        
        notificationDataService.$noticeNotiList
            .sink { [weak self] noticeNotiList in
                self?.noticeNotiList = noticeNotiList
            }
            .store(in: &cancellables)
        
        notificationDataService.$notiSections
            .sink { [weak self] notiSections in
                self?.notiSections = notiSections
            }
            .store(in: &cancellables)
        
        Publishers.CombineLatest4($projectNotiList, $todoNotiList, $challengeNotiList, $noticeNotiList)
            .map { projectList, todoList, challengeList, noticeList in
                return projectList + todoList + challengeList + noticeList
            }
            .sink { [weak self] allNotiList in
                self?.allNotiList = allNotiList
            }
            .store(in: &cancellables)

    }
    
    func filterNotifications(type: NotificationType) {
        switch type {
        case .all:
            self.filteredNotiList = self.allNotiList
        case .project:
            self.filteredNotiList = self.projectNotiList
        case .todo:
            self.filteredNotiList = self.todoNotiList
        case .challenge:
            self.filteredNotiList = self.challengeNotiList
        case .notice:
            self.filteredNotiList = self.noticeNotiList
        }
    }
    
}
