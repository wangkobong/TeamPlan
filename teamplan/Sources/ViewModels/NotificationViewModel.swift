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
    @Published var challengeNotiList: [NotificationModel] = []
    @Published var filteredNotiList: [NotificationModel] = []
    @Published var isViewModelReady: Bool = false
    
    private let notifySC = NotificationService()
    private var cancellables = Set<AnyCancellable>()
    
    @MainActor
    func prepareViewModel(with homeVM: HomeViewModel) {
        Task {
            do {
                self.prepareNotiSection()
                //self.projectNotiList = try await prepareProjectNotify(with: homeVM)
                self.challengeNotiList = try await prepareChallengeNotify()
                self.addSubscribers()
                self.filterNotifications(type: .all)
                self.isViewModelReady = true
                print("[NotificationViewModel] Successfully prepared viewModel")
            } catch {
                print("[NotificationViewModel] Failed to prepare viewModel: \(error.localizedDescription)")
            }
        }
    }
    
    private func prepareNotiSection() {
        self.notiSections = [
            NotificationSection(title: "전체", type: .all, isSelected: true),
            NotificationSection(title: "프로젝트", type: .project),
            NotificationSection(title: "도전과제", type: .challenge)
        ]
    }
    
    /*
    private func prepareProjectNotify(with homeVM: HomeViewModel) async throws -> [NotificationModel] {
        let projectList = homeVM.userData.projectsDTOs
        let userName = homeVM.userData.userName
        
        return try await withThrowingTaskGroup(of: NotificationModel?.self) { group in
            for project in projectList {
                group.addTask {
                    let type = await self.notifySC.identifyProjectForNotify(with: project, on: Date())
                    return self.createNotificationModel(for: project, type: type, userName: userName)
                }
            }
            
            var notificationList: [NotificationModel] = []
            for try await notification in group {
                if let notification = notification {
                    notificationList.append(notification)
                }
            }
            return notificationList
        }
    }
    */
     
    private func createNotificationModel(for project: ProjectObject, type: projectNotification, userName: String) -> NotificationModel? {
        let today = Date()
        switch type {
        case .halfway:
            return NotificationModel(
                title: project.title,
                description: NotificationDesc.halfway(userName: userName, title: project.title).toString,
                type: .project,
                isSelected: false,
                date: today
            )
        case .nearDeadline:
            let totalPeriod = try? Utilities().calculateDatePeriod(with: project.startedAt, and: project.deadline)
            let progressedPeriod = try? Utilities().calculateDatePeriod(with: project.startedAt, and: today)
            let dayLeft = (totalPeriod ?? 0) - (progressedPeriod ?? 0)
            return NotificationModel(
                title: project.title,
                description: NotificationDesc.nearDeadline(userName: userName, title: project.title, dayLeft: dayLeft).toString,
                type: .project,
                isSelected: false,
                date: today
            )
        case .oneDayLeft:
            return NotificationModel(
                title: project.title,
                description: NotificationDesc.oneDayBefore(userName: userName, title: project.title).toString,
                type: .project,
                isSelected: false,
                date: today
            )
        case .theDay:
            return NotificationModel(
                title: project.title,
                description: NotificationDesc.deadline(userName: userName, title: project.title).toString,
                type: .project,
                isSelected: false,
                date: today
            )
        case .explode:
            return NotificationModel(
                title: project.title,
                description: NotificationDesc.doomsDay(userName: userName, title: project.title).toString,
                type: .project,
                isSelected: false,
                date: today
            )
        default:
            return nil
        }
    }
    
    private func prepareChallengeNotify() async throws -> [NotificationModel] {
        // Simplified for demonstration purposes
        return [
            NotificationModel(title: "도전과제 알림 1", description: "알림 본문을 적어주세요 알림 본문을 적어주세요", type: .challenge, isSelected: false, date: Date().addingTimeInterval(-86400)),
            NotificationModel(title: "도전과제 알림 2", description: "알림 본문을 적어주세요 알림 본문을 적어주세요", type: .challenge, isSelected: false, date: Date()),
            NotificationModel(title: "도전과제 알림 3", description: "알림 본문을 적어주세요 알림 본문을 적어주세요", type: .challenge, isSelected: false, date: Date().addingTimeInterval(86400)),
        ]
    }
    
    private func addSubscribers() {
        Publishers.CombineLatest($projectNotiList, $challengeNotiList)
            .map { $0 + $1 }
            .assign(to: &$allNotiList)
    }
    
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
}



