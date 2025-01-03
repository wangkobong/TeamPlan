//
//  NotificationViewModel.swift
//  teamplan
//
//  Created by sungyeon kim on 2023/08/12.
//  Copyright © 2023 team1os. All rights reserved.

//  Notification OnTapGesture 동작 시, isCheck Status 변경필요

import Foundation

final class NotificationViewModel: ObservableObject {
    
    @Published var isRedirectNeed: Bool = false
    @Published var isNewNotifyAdded: Bool = false
    
    @Published var notiSections: [NotificationSection] = []
    @Published var filteredNotiList: [NotificationModel] = []
    
    private let userId: String
    private let service: LiteNotifyService
    private var objectList: [NotificationObject]
    private var modelList: [NotificationModel]
    
    @MainActor
    init(){
        let volt = VoltManager.shared
        if let userId = volt.getUserId(){
            self.userId = userId
            self.objectList = []
            self.modelList = []
            self.service = LiteNotifyService(userId: userId)
        } else {
            self.userId = "unknown"
            self.objectList = []
            self.modelList = []
            self.service = LiteNotifyService(userId: "unknown")
            self.isRedirectNeed = true
            print("[NotifyViewModel] Failed to prepared viewModel")
        }
    }
    
    //MARK: Prepapre
    
    func prepareViewModel() async -> Bool {
        guard await service.fetchNotifyList() else {
            return false
        }
        prepareNotifyList()
        checkNewNotify()
        
        await prepareNotiySection()
        await filterNotifications(type: .all)
        return true
    }

    @MainActor
    func filterNotifications(type: NotificationType) {
        self.filteredNotiList = []
        
        switch type {
        case .all:
            self.filteredNotiList = self.modelList
        case .project:
            self.filteredNotiList = self.modelList.filter{ $0.type == .project }
        case .challenge:
            self.filteredNotiList = self.modelList.filter{ $0.type == .challenge }
        }
    }
    
    func checkNewNotify() {
        if modelList.contains(where: {$0.isSelected == false}){
            self.isNewNotifyAdded = true
        } else {
            self.isNewNotifyAdded = false
        }
    }
    
    private func prepareNotifyList() {
        self.objectList = []
        self.modelList = []
        
        self.objectList = service.notifyList
        if objectList.isEmpty {
            return
        }
        
        let sortedNotifyList = objectList.sorted { first, second in
            if first.isCheck != second.isCheck {
                return !first.isCheck
            } else {
                return first.updateAt > second.updateAt
            }
        }
        for notify in sortedNotifyList {
            let model = createNotifyModel(with: notify)
            self.modelList.append(model)
        }
    }
    
    @MainActor
    private func prepareNotiySection() {
        self.notiSections = [
            NotificationSection(title: "전체", type: .all, isSelected: true),
            NotificationSection(title: "목표관리", type: .project),
            NotificationSection(title: "도전과제", type: .challenge)
        ]
    }
    
}

//MARK: update status

extension NotificationViewModel {
    
    func updateNotify(with model: NotificationModel) async -> Bool {
        let updatedAt = Date()
        
        guard let updated = createNotifyUpdateDTO(with: model, at: updatedAt) else {
            return false
        }
        guard service.checkedNotifyProcedure(with: updated) else {
            return false
        }
        if updateNotifyList(with: model) {
            checkNewNotify()
            await filterNotifications(type: .all)
            return true
        } else {
            return false
        }
    }
    
    private func updateNotifyList(with prevModel: NotificationModel) -> Bool {
        switch prevModel.type {
        case .project:
            guard let index = self.modelList.firstIndex(where: {$0.type == .project && $0.id == prevModel.id}) else {
                return false
            }
            self.modelList[index].isSelected = true

        case .challenge:
            guard let index = self.modelList.firstIndex(where: {$0.type == .challenge && $0.id == prevModel.id}) else {
                return false
            }
            self.modelList[index].isSelected = true

        case .all:
            break
        }
        return true
    }
}

//MARK: util

extension NotificationViewModel {

    private func createNotifyModel(with object: NotificationObject) -> NotificationModel {
        var notifyType: NotificationType
        var notifyId: Int
        
        switch object.category {
        case .challenge:
            notifyType = .challenge
            notifyId = object.challengeId ?? 0
        case .project:
            notifyType = .project
            notifyId = object.projectId ?? 0
        case .unknown:
            notifyType = .all
            notifyId = 0
        }
        let model = NotificationModel(
            id: notifyId,
            title: object.title,
            description: object.desc,
            type: notifyType,
            isSelected: object.isCheck,
            date: object.updateAt
        )
        return model
    }

    private func createNotifyUpdateDTO(with model: NotificationModel, at updatedAt: Date) -> NotifyUpdateDTO? {
        var dto: NotifyUpdateDTO
        
        switch model.type {
        case .project:
            if let object = objectList.first(where: {$0.projectId == model.id}) {
                guard let notifyId = object.projectId else {
                    return nil
                }
                dto = NotifyUpdateDTO(
                    userId: userId,
                    projectId: notifyId,
                    updateAt: updatedAt,
                    isCheck: true
                )
            } else {
                print("[NotifyViewModel] Failed to search update target notify")
                return nil
            }
        case .challenge:
            if let object = objectList.first(where: {$0.challengeId == model.id}) {
                guard let notifyId = object.challengeId else {
                    return nil
                }
                dto = NotifyUpdateDTO(
                    userId: userId,
                    challengeId: notifyId,
                    updateAt: updatedAt,
                    isCheck: true
                )
            } else {
                print("[NotifyViewModel] Failed to search update target notify")
                return nil
            }
        case .all:
            dto = NotifyUpdateDTO()
            break;
        }
        return dto
    }
}



