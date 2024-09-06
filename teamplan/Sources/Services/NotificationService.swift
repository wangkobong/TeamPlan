//
//  NotificationService.swift
//  teamplan
//
//  Created by 크로스벨 on 6/3/24.
//  Copyright © 2024 team1os. All rights reserved.
//

import CoreData
import Foundation

actor NotifyDataManager {
    private var notificationList: [NotificationObject] = []
    private var newNotifyList: [NotificationObject] = []
    private var truncateNotifyList: [Int : NotificationCategory] = [:]
    
    func addNotify(_ data: NotificationObject) {
        notificationList.append(data)
    }
    
    func addNewNotify(_ data: NotificationObject) {
        newNotifyList.append(data)
    }
    
    func addTruncateNotify(_ notifyId: Int, _ type: NotificationCategory) {
        truncateNotifyList[notifyId] = type
    }
    
    func getNotify() -> [NotificationObject] {
        return notificationList
    }
    
    func getNewNotifyList() -> [NotificationObject] {
        return newNotifyList
    }
    
    func getTruncateList() -> [Int : NotificationCategory] {
        return truncateNotifyList
    }
}

final class NotificationService {
    
    // shared
    let notifyDataManager: NotifyDataManager
    
    private let today: Date
    private let userId: String
    private let storageManager: LocalStorageManager
    
    private let util: Utilities
    private let statCD: StatisticsServicesCoredata
    private let projectCD: ProjectServicesCoredata
    private let challengeCD: ChallengeServicesCoredata
    private let notifyCD: NotificationServicesCoredata
    
    private var statData: StatisticsObject
    private var projectList: [ProjectObject]
    private var projectNotifyList: [Int : NotificationObject]
    private var challengeList: [ChallengeObject]
    private var challengeNotifyList: [Int : NotificationObject]
    
    private var updateNeedNotifyList: [NotifyUpdateDTO]
    private var previousNotifyList: [NotificationObject]
    private var truncateNotifyList: [Int : NotificationCategory]
    
    init(userId: String) {
        self.today = Date()
        self.userId = userId
        self.notifyDataManager = NotifyDataManager()
        self.storageManager = LocalStorageManager.shared
        
        self.util = Utilities()
        self.statCD = StatisticsServicesCoredata()
        self.projectCD = ProjectServicesCoredata()
        self.challengeCD = ChallengeServicesCoredata()
        self.notifyCD = NotificationServicesCoredata()
        
        self.statData = StatisticsObject()
        self.projectList = []
        self.projectNotifyList = [:]
        self.challengeList = []
        self.challengeNotifyList = [:]
        
        self.updateNeedNotifyList = []
        self.previousNotifyList = []
        self.truncateNotifyList = [:]
    }
    
    //MARK:  ----- Main -----
    
    func firstLoginExecutor() async -> Bool {
        
        // fetch
        guard fullFetchExecutor() else {
            return false
        }
        
        // preprocessing
        guard await preprocessingExecutor() else {
            return false
        }

        if await updateExecutor() {
            await constructExecutor()
            return true
        } else {
            return false
        }
    }
    
    func fetchExecutor() async -> Bool {
        // fetch
        guard semiFetchExecutor() else {
            return false
        }
        await constructExecutor()
        return true
    }
    
    func afterUpdateExecutor() {
        // update single notify (storage & local)
    }
}

//MARK:  ----- Fetch Data -----

extension NotificationService {
    
    private func fullFetchExecutor() -> Bool {
        let context = storageManager.context
        var results = [Bool]()
        
        context.performAndWait {
            results = [
                fetchNotifyList(with: context, isFullFetch: true),
                fetchStatData(with: context),
                fetchValidProject(with: context),
                fetchMyChallenges(with: context)
            ]
        }
        return results.allSatisfy{$0}
    }
    
    private func semiFetchExecutor() -> Bool {
        let context = storageManager.context
        
        return context.performAndWait {
            return fetchNotifyList(with: context, isFullFetch: false)
        }
    }
    
    // previous notify
    private func fetchNotifyList(with context: NSManagedObjectContext, isFullFetch: Bool) -> Bool {
        
        guard notifyCD.getTotalObjectList(context, with: userId) else {
            print("[NotifySC] Failed to get notify list")
            return false
        }
        let notifyList = notifyCD.objectList
        
        if isFullFetch {
            for notify in notifyList {
                if let challengeId = notify.challengeId {
                    challengeNotifyList[challengeId] = notify
                }
                if let projectId = notify.projectId {
                    projectNotifyList[projectId] = notify
                }
            }
        } else {
            previousNotifyList.append(contentsOf: notifyList)
        }
        return true
    }
    
    // statData
    private func fetchStatData(with context: NSManagedObjectContext) -> Bool {
        do {
            guard try statCD.getObject(context: context, userId: userId) else {
                print("[NotifySC] Error detected while converting StatEntity to object")
                return false
            }
            self.statData = statCD.object
            return true
        } catch {
            print(error.localizedDescription)
            return false
        }
    }
    
    // project
    private func fetchValidProject(with context: NSManagedObjectContext) -> Bool {
        do {
            guard try projectCD.getValidObjects(context: context, with: userId) else {
                print("[NotifySC] Failed to get valid project")
                return false
            }
            self.projectList = projectCD.objectList
            return true
        } catch {
            print(error.localizedDescription)
            return false
        }
    }
    
    // myChallenge
    private func fetchMyChallenges(with context: NSManagedObjectContext) -> Bool {
        do {
            guard try challengeCD.getMyObjects(context: context, userId: userId) else {
                print("[NotifySC] Failed to get myChallenges")
                return false
            }
            self.challengeList = challengeCD.objects
            return true
        } catch {
            print(error.localizedDescription)
            return false
        }
    }
}

//MARK:  ----- Preprocessing  -----

extension NotificationService {
    
    private func preprocessingExecutor() async -> Bool {
        async let isProjectNotifyProceed = preprocessingProjectNotify()
        async let isChallengeNotifyProceed = preprocessingChallengeNotify()
        
        let results = await [isProjectNotifyProceed, isChallengeNotifyProceed]
        if results.allSatisfy({$0}){
            print("[NotifySC] Successfully proceed project & challenge notify")
            return true
        } else {
            print("[NotifySC] Failed to proceed project & challenge notify")
            return false
        }
    }
    
    //MARK: proejct
    
    private func preprocessingProjectNotify() async -> Bool {
        
        // check: subject empty
        if projectList.isEmpty {
            print("[NotifySC] There is no valid project to create notify")
            return true
        }
        
        for project in projectList {
            let candidateNotifyType = identifyProjectForNotify(with: project, on: today)
            
            // check: truncate notify
            if let previousNotify = projectNotifyList[project.projectId] {
                if isTrucateNeed(notify: previousNotify) {
                    await notifyDataManager.addTruncateNotify(project.projectId, .project)
                    continue
                }
                // check: update notify
                if candidateNotifyType != previousNotify.projectStatus {
                    updateNeedNotifyList.append(
                        updateProjectNotify(data: project, newType: candidateNotifyType)
                    )
                }
                // check: new notify
            } else {
                await notifyDataManager.addNewNotify(
                    createProjectNotify(data: project, type: candidateNotifyType, at: today)
                )
            }
        }
        return true
    }
    
    private func createProjectNotify(data: ProjectObject, type: ProjectNotification, at updateAt: Date) -> NotificationObject {
        
        let desc = getProjectNotifyDesc(with: type)
        return NotificationObject(
            userId: userId,
            projectId: data.projectId,
            category: .project,
            title: data.title,
            desc: desc,
            updateAt: updateAt,
            isCheck: false
        )
    }
    
    private func updateProjectNotify(data: ProjectObject, newType: ProjectNotification) -> NotifyUpdateDTO {
        let newDesc = getProjectNotifyDesc(with: newType)
        return NotifyUpdateDTO(
            userId: userId,
            projectId: data.projectId,
            projectStatus: newType,
            desc: newDesc,
            updateAt: today
        )
    }

    //MARK: myChallenge

    private func preprocessingChallengeNotify() async -> Bool {
        
        if challengeList.isEmpty {
            print("[NotifySC] There is no registed myChallenge to create notify")
            return true
        }
        
        for challenge in challengeList {
            
            // check: too old notify
            if let previousNotify = challengeNotifyList[challenge.challengeId] {
                if isTrucateNeed(notify: previousNotify) {
                    await notifyDataManager.addTruncateNotify(challenge.challengeId, .challenge)
                }
            }
            
            // check: new candidate
            let userProgress = getUserProgressForChallengeNotify(with: challenge.type)
            if challenge.goal <= userProgress {
                await notifyDataManager.addNewNotify(
                    createChallengeNotify(with: challenge, at: today)
                )
            }
        }
        return true
    }
    
    private func createChallengeNotify(with object: ChallengeObject, at date: Date) -> NotificationObject {
        return NotificationObject(
            userId: userId,
            category: .challenge,
            title: object.title,
            desc: "도전과제가 완료되었습니다! 도전을 완료하여 물방울을 획득해주세요.",
            updateAt: date,
            isCheck: false
        )
    }
    
    //MARK: util
    
    // identify
    private func identifyLegacyNotify() {
        
        for notify in previousNotifyList {
            if isTrucateNeed(notify: notify) {
                if let projectId = notify.projectId {
                    truncateNotifyList[projectId] = .project
                }
                if let challengeId = notify.challengeId {
                    truncateNotifyList[challengeId] = .challenge
                }
            }
        }
    }
    
    // condition
    private func isTrucateNeed(notify: NotificationObject) -> Bool {
        
        // Checked
        if notify.isCheck && notify.updateAt < today {
            return true
        }
        // UnChecked, but expired
        let expirationDate = Calendar.current.date(byAdding: .weekOfYear, value: 2, to: notify.updateAt) ?? notify.updateAt
        if !notify.isCheck && expirationDate < today {
            return true
        }
        return false
    }
}

//MARK: ----- Update -----

extension NotificationService {
    
    // main
    private func updateExecutor() async -> Bool {
        let context = storageManager.context
        
        if await !notifyDataManager.getTruncateList().isEmpty {
            guard await applyTruncateResult(context) else {
                print("[UpdateExecutor] Failed to apply truncate results.")
                return false
            }
        }

        if !updateNeedNotifyList.isEmpty {
            guard applyUpdateResult(context) else {
                print("[UpdateExecutor] Failed to apply update results.")
                return false
            }
        }

        if await !notifyDataManager.getNewNotifyList().isEmpty {
            guard await applyAddNewResult(context) else {
                print("[UpdateExecutor] Failed to apply new additions.")
                return false
            }
        }
        return true
    }
    
    //MARK: add new
    private func applyAddNewResult(_ context: NSManagedObjectContext) async -> Bool {
        let storageResult = await applyAddNewResultToStorage(context)
        if storageResult {
            await applyAddNewResultToLocal()
            return true
        } else {
            return false
        }
    }
    
    private func applyAddNewResultToStorage(_ context: NSManagedObjectContext) async -> Bool {
        for notify in await notifyDataManager.getNewNotifyList() {
            notifyCD.setObject(context, object: notify)
        }
        return storageManager.saveContext()
    }
    
    private func applyAddNewResultToLocal() async {
        for notify in await notifyDataManager.getNewNotifyList() {
            await notifyDataManager.addNotify(notify)
        }
    }
    
    //MARK: truncate
    private func applyTruncateResult(_ context: NSManagedObjectContext) async -> Bool {
        let storageResult = await applyTruncateResultToStorage(context)
        if storageResult {
            await applyTruncateResultToLocal()
            return true
        } else {
            return false
        }
    }
    
    private func applyTruncateResultToStorage(_ context: NSManagedObjectContext) async -> Bool {
        let turncateList = await notifyDataManager.getTruncateList()
        
        return context.performAndWait {
            if notifyCD.deleteObjectList(context, userId: userId, notifyList: turncateList) {
                return storageManager.saveContext()
            } else {
                print("[NotifySC] Failed to truncate legacy notify")
                return false
            }
        }
    }
    
    private func applyTruncateResultToLocal() async {
        let truncateList = await notifyDataManager.getTruncateList()
        previousNotifyList.removeAll { notify in
            if let projectId = notify.projectId, truncateList[projectId] == .project {
                return true
            }
            if let challengeId = notify.challengeId, truncateList[challengeId] == .challenge {
                return true
            }
            return false
        }
    }
    
    //MARK: update
    private func applyUpdateResult(_ context: NSManagedObjectContext) -> Bool {
        let storageResult = applyUpdateResultToStorage(context)
        if storageResult {
            applyUpdateResultToLocal()
            return true
        } else {
            return false
        }
    }
    
    private func applyUpdateResultToLocal() {
        for updateDTO in updateNeedNotifyList {
            if let index = previousNotifyList.firstIndex(where: { notify in
                (updateDTO.projectId != nil && notify.projectId == updateDTO.projectId) ||
                (updateDTO.challengeId != nil && notify.challengeId == updateDTO.challengeId)
            }) {
                previousNotifyList[index].update(with: updateDTO)
            }
        }
    }

    private func applyUpdateResultToStorage(_ context: NSManagedObjectContext) -> Bool {
        if notifyCD.updateObject(context, dtoList: updateNeedNotifyList) {
            return storageManager.saveContext()
        } else {
            print("[NotifySC] Failed to process update notify")
            return false
        }
    }
}

//MARK: ----- Construct -----

extension NotificationService {
    
    private func constructExecutor() async {
        
        if !previousNotifyList.isEmpty {
            for notify in previousNotifyList {
                await notifyDataManager.addNotify(notify)
            }
        }
        
        let newNotifyList = await notifyDataManager.getNewNotifyList()
        if !newNotifyList.isEmpty {
            for notify in newNotifyList {
                await notifyDataManager.addNotify(notify)
            }
        }
    }
}
//MARK: ----- Util -----

extension NotificationService {
    
    private func addNotify(_ object: NotificationObject) async {
        
    }
    
    private func getProjectNotifyDesc(with type: ProjectNotification) -> String {
        switch type {
        case .halfway:
            return "마감일까지 절반 남았습니다!"
        case .nearDeadline:
            return "마감일까지 얼마남지 않았습니다!"
        case .oneDayLeft:
            return "마감일까지 하루 남았습니다!"
        case .theDay:
            return "목표 마감일입니다!"
        default:
            return "진행중인 목표입니다"
        }
    }
    
    func identifyProjectForNotify(with object: ProjectObject, on today: Date) -> ProjectNotification {
        do {
            let totalPeriod = try util.calculateDatePeriod(with: object.startedAt, and: object.deadline)
            let progressedPeriod = try util.calculateDatePeriod(with: object.startedAt, and: today)
            
            if progressedPeriod == totalPeriod / 2 {
                return .halfway
                
            } else if progressedPeriod == (totalPeriod * 3 / 4) {
                return .nearDeadline
                
            } else if progressedPeriod == (totalPeriod - 1) {
                return .oneDayLeft
                
            } else if progressedPeriod == totalPeriod {
                return .theDay
                
            } else if progressedPeriod > totalPeriod {
                return .explode
                
            } else {
                return .ongoing
            }
        } catch {
            print("[NotifyService] Failed to calculate project period")
            return .unknown
        }
    }
    
    func getUserProgressForChallengeNotify(with type: ChallengeType) -> Int {
        switch type {
        case .onboarding:
            return 1
        case .serviceTerm:
            return statData.term
        case .totalTodo:
            return statData.totalRegistedTodos
        case .projectAlert:
            return statData.totalAlertedProjects
        case .projectFinish:
            return statData.totalFinishedProjects
        case .waterDrop:
            return statData.drop
        case .unknownType:
            return 0
        }
    }
}
