//
//  NotificationViewModel.swift
//  teamplan
//
//  Created by sungyeon kim on 2023/08/12.
//  Copyright © 2023 team1os. All rights reserved.
//

import Combine
import Foundation

final class NotificationViewModel: ObservableObject {
    
    @Published var isViewModelReady: Bool = false
    @Published var isRedirectNeed: Bool = false
    
    @Published var notiSections: [NotificationSection] = []
    @Published var allNotiList: [NotificationModel] = []
    @Published var projectNotiList: [NotificationModel] = []
    @Published var challengeNotiList: [NotificationModel] = []
    @Published var filteredNotiList: [NotificationModel] = []
    
    private let userId: String
    private let service: NotificationService
    private var cancellables = Set<AnyCancellable>()
    
    init(){
        let volt = VoltManager.shared
        if let userId = volt.getUserId(){
            self.userId = userId
            self.service = NotificationService(userId: userId)
        } else {
            print("[NotifyViewModel] Failed to prepared viewModel")
            self.userId = "unknown"
            self.service = NotificationService(userId: "unknown")
            self.isRedirectNeed = true
        }
    }
    
    func prepareViewModel() async -> Bool {
        
        guard await service.fetchExecutor() else {
            return false
        }
        guard await prepareNotifyData() else {
            return false
        }
        await prepareNotiSection()
        await filterNotifications(type: .all)
        await addSubscribers()
        return true
    }
    
    @MainActor
    func filterNotifications(type: NotificationType) {
        switch type {
        case .all:
            self.filteredNotiList = self.allNotiList
        case .project:
            self.filteredNotiList = self.projectNotiList
        case .challenge:
            self.filteredNotiList = self.challengeNotiList
        }
    }
    
    @MainActor
    private func prepareNotiSection() {
        self.notiSections = [
            NotificationSection(title: "전체", type: .all, isSelected: true),
            NotificationSection(title: "프로젝트", type: .project),
            NotificationSection(title: "도전과제", type: .challenge)
        ]
    }
    
    private func prepareNotifyData() async -> Bool {
        let notifyList = await service.notifyDataManager.getNotify()
        
        await MainActor.run {
            for notify in notifyList {
                let model = createNotifyModel(with: notify)
                allNotiList.append(model)
                
                if model.type == .project {
                    projectNotiList.append(model)
                }
                if model.type == .challenge {
                    challengeNotiList.append(model)
                }
            }
        }
        return true
    }
    
    private func createNotifyModel(with object: NotificationObject) -> NotificationModel {
        var notifyType: NotificationType
        switch object.category {
        case .challenge:
            notifyType = .challenge
        case .project:
            notifyType = .project
        case .unknown:
            notifyType = .all
        }
        
        return NotificationModel(
            title: object.title,
            description: object.desc,
            type: notifyType,
            isSelected: object.isCheck,
            date: object.updateAt
        )
    }
    
    @MainActor
    private func addSubscribers() {
        Publishers.CombineLatest($projectNotiList, $challengeNotiList)
            .map { $0 + $1 }
            .assign(to: &$allNotiList)
    }
}



