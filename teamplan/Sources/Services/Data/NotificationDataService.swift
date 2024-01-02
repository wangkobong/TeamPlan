//
//  NotificationDataService.swift
//  teamplan
//
//  Created by sungyeon kim on 2023/08/12.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation
import Combine

final class NotificationDataService {
    
    @Published var notiSections: [NotificationSection] = []
    @Published var projectNotiList: [NotificationModel] = []
    @Published var todoNotiList: [NotificationModel] = []
    @Published var challengeNotiList: [NotificationModel] = []
    @Published var noticeNotiList: [NotificationModel] = []
    var terms: AnyCancellable?
    
    init() {
        getNoties()
        getSections()
    }
    
    private func getNoties() {
        // 나중에 이곳에서 fetch noties
        let projectNotiListFromServer: [NotificationModel] = [
            NotificationModel(title: "프로젝트 알림 1", description: "알림 본문을 적어주세요 알림 본문을 적어주세요", type: .project, isSelected: false, date: Date().addingTimeInterval(-86400)),
            NotificationModel(title: "프로젝트 알림 2", description: "알림 본문을 적어주세요 알림 본문을 적어주세요", type: .project, isSelected: false, date: Date()),
            NotificationModel(title: "프로젝트 알림 3", description: "알림 본문을 적어주세요 알림 본문을 적어주세요", type: .project, isSelected: false, date: Date().addingTimeInterval(86400)),
        ]
        
        let todoNotiListFromServer: [NotificationModel] = [
            NotificationModel(title: "투두 알림 1", description: "알림 본문을 적어주세요 알림 본문을 적어주세요", type: .todo, isSelected: false, date: Date().addingTimeInterval(-86400)),
            NotificationModel(title: "투두 알림 2", description: "알림 본문을 적어주세요 알림 본문을 적어주세요", type: .todo, isSelected: false, date: Date()),
            NotificationModel(title: "투두 알림 3", description: "알림 본문을 적어주세요 알림 본문을 적어주세요", type: .todo, isSelected: false, date: Date().addingTimeInterval(86400)),
        ]
        
        let challengeNotiListFromServer: [NotificationModel] = [
            NotificationModel(title: "도전과제 알림 1", description: "알림 본문을 적어주세요 알림 본문을 적어주세요", type: .challenge, isSelected: false, date: Date().addingTimeInterval(-86400)),
            NotificationModel(title: "도전과제 알림 2", description: "알림 본문을 적어주세요 알림 본문을 적어주세요", type: .challenge, isSelected: false, date: Date()),
            NotificationModel(title: "도전과제 알림 3", description: "알림 본문을 적어주세요 알림 본문을 적어주세요", type: .challenge, isSelected: false, date: Date().addingTimeInterval(86400)),
        ]
        
        let noticeNotiListFromServer: [NotificationModel] = [
            NotificationModel(title: "공지사항 알림 1", description: "알림 본문을 적어주세요 알림 본문을 적어주세요", type: .project, isSelected: false, date: Date().addingTimeInterval(-86400)),
            NotificationModel(title: "공지사항 알림 2", description: "알림 본문을 적어주세요 알림 본문을 적어주세요", type: .project, isSelected: false, date: Date()),
            NotificationModel(title: "공지사항 알림 3", description: "알림 본문을 적어주세요 알림 본문을 적어주세요", type: .project, isSelected: false, date: Date().addingTimeInterval(86400)),
        ]
        
        
        self.projectNotiList = projectNotiListFromServer
        self.todoNotiList = todoNotiListFromServer
        self.challengeNotiList = challengeNotiListFromServer
        self.noticeNotiList = noticeNotiListFromServer
    }
    
    private func getSections() {
        let notiSectionsFromServer: [NotificationSection] = [
            NotificationSection(title: "전체", type: .all, isSelected: true),
            NotificationSection(title: "프로젝트", type: .project),
            NotificationSection(title: "투두", type: .todo),
            NotificationSection(title: "도전과제", type: .challenge),
            NotificationSection(title: "공지사항", type: .notice),
        ]
        
        self.notiSections = notiSectionsFromServer
    }
}
