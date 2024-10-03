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
    private let statCD: StatisticsServicesCoredata
    private let projectCD: ProjectServicesCoredata
    private let notifyCD: NotificationServicesCoredata
    private let challengeCD: ChallengeServicesCoredata
    
    private var statData: StatisticsObject
    private var projectList: [ProjectObject]
    
    private var challengeList: [ChallengeObject]
    private var challengeNotifyList: [Int : NotificationObject]
    private var projectNotifyList: [Int : NotificationObject]
    
    private var updateNeedNotifyList: [NotifyUpdateDTO]
    private var previousNotifyList: [NotificationObject]
    private var truncateNotifyList: [Int : NotificationCategory]
    
    private let util: Utilities
    private let storageManager: LocalStorageManager
    
    // background version
    init(userId: String, processedDate: Date) {
        self.today = processedDate
        self.userId = userId
        self.statCD = StatisticsServicesCoredata()
        self.projectCD = ProjectServicesCoredata()
        self.notifyCD = NotificationServicesCoredata()
        self.challengeCD = ChallengeServicesCoredata()
        
        self.statData = StatisticsObject()
        self.projectList = []
        
        self.challengeList = []
        self.notifyDataManager = NotifyDataManager()
        self.challengeNotifyList = [:]
        self.projectNotifyList = [:]
        self.updateNeedNotifyList = []
        self.previousNotifyList = []
        self.truncateNotifyList = [:]
        
        self.util = Utilities()
        self.storageManager = LocalStorageManager.shared
    }
    
    // login version
    init(
        loginDate: Date,
        userId: String,
        statData: StatisticsObject,
        projectList: [ProjectObject],
        statCD: StatisticsServicesCoredata,
        projectCD: ProjectServicesCoredata,
        challengeCD: ChallengeServicesCoredata,
        storageManager: LocalStorageManager,
        util: Utilities
    ){
        self.today = loginDate
        self.userId = userId
        self.statCD = statCD
        self.projectCD = projectCD
        self.challengeCD = challengeCD
        self.notifyCD = NotificationServicesCoredata()
        
        self.statData = statData
        self.projectList = projectList
        
        self.challengeList = []
        self.notifyDataManager = NotifyDataManager()
        self.challengeNotifyList = [:]
        self.projectNotifyList = [:]
        self.updateNeedNotifyList = []
        self.previousNotifyList = []
        self.truncateNotifyList = [:]
        
        self.util = util
        self.storageManager = storageManager
    }
    
    //MARK:  ----- Main -----
    
    func loginExecutor() async -> Bool {
        
        // fetch
        guard loginFetchExecutor() else {
            return false
        }
        
        // preprocessing
        guard await preprocessingExecutor() else {
            return false
        }

        // update
        return await updateExecutor()
    }
    
    func backgroundExecutor() async -> Bool {
        
        guard backgroundFetchExecutor() else {
            return false
        }
        
        // preprocessing
        guard await preprocessingExecutor() else {
            return false
        }

        // update
        return await updateExecutor()
    }
}

//MARK:  ----- Fetch Data -----

extension NotificationService {
    
    private func loginFetchExecutor() -> Bool {
        let context = storageManager.context
        
        return context.performAndWait {
            let isNotifyFetched = fetchNotifyList(context)
            let isMyChallengeFetched = fetchMyChallenges(context)
            
            return isNotifyFetched && isMyChallengeFetched
        }
    }
    
    private func backgroundFetchExecutor() -> Bool {
        let context = storageManager.createBackgroundContext()
        var results = [Bool]()
        
        context.performAndWait {
            results = [
                fetchNotifyList(context),
                fetchMyChallenges(context),
                fetchProjectList(context),
                fetchStatData(context)
            ]
        }
        return results.allSatisfy{$0}
    }
    
    // previous notify
    private func fetchNotifyList(_ context: NSManagedObjectContext) -> Bool {
        
        guard notifyCD.fetchTotalObjectList(context, with: userId) else {
            print("[NotifySC] Failed to get notify list")
            return false
        }
        let notifyList = notifyCD.objectList
        for notify in notifyList {
            if let challengeId = notify.challengeId {
                challengeNotifyList[challengeId] = notify
            }
            if let projectId = notify.projectId {
                projectNotifyList[projectId] = notify
            }
            self.previousNotifyList.append(notify)
        }
        return true
    }
    
    // myChallenge
    private func fetchMyChallenges(_ context: NSManagedObjectContext) -> Bool {
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
    
    // projects
    private func fetchProjectList(_ context: NSManagedObjectContext) -> Bool {
        do {
            guard try projectCD.getValidObjects(context: context, with: userId) else {
                print("[NotifySC] Failed to get valid project from storage")
                return false
            }
            self.projectList = projectCD.objectList
            return true
        } catch {
            print(error.localizedDescription)
            return false
        }
    }
    
    
    // statistics
    private func fetchStatData(_ context: NSManagedObjectContext) -> Bool {
        do {
            guard try statCD.getObject(context: context, userId: userId) else {
                print("[NotifySC] Failed to get statData from storage")
                return false
            }
            self.statData = statCD.object
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
            
            // check: already exist notify
            if let previousNotify = projectNotifyList[project.projectId] {
                
                // check: truncate notify
                if isTrucateNeed(notify: previousNotify) {
                    await notifyDataManager.addTruncateNotify(project.projectId, .project)
                    continue
                }
                // check: update notify
                if candidateNotifyType != previousNotify.projectStatus {
                    updateNeedNotifyList.append(
                        updateProjectNotify(data: project, newType: candidateNotifyType)
                    )
                    continue
                }
                // check: previous notify
                await notifyDataManager.addNotify(previousNotify)
                
            // check: new notify
            } else {
                let object = createProjectNotify(data: project, type: candidateNotifyType, at: today)
                await notifyDataManager.addNewNotify(object)
            }
        }
        return true
    }
    
    private func createProjectNotify(data: ProjectObject, type: ProjectNotification, at updateAt: Date) -> NotificationObject {
        
        let desc = getProjectNotifyDesc(with: type)
        return NotificationObject(
            userId: userId,
            projectId: data.projectId,
            projectStatus: type,
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
            updateAt: today,
            isCheck: false
        )
    }

    //MARK: myChallenge

    private func preprocessingChallengeNotify() async -> Bool {
        if challengeList.isEmpty {
            print("[NotifySC] There is no registed myChallenge to create notify")
            return true
        }
        print(challengeNotifyList)
        
        for challenge in challengeList {
            
            // check: already exist notify
            if let previousNotify = challengeNotifyList[challenge.challengeId] {
                
                // check: truncate notify
                if isTrucateNeed(notify: previousNotify) {
                    await notifyDataManager.addTruncateNotify(challenge.challengeId, .challenge)
                    continue
                }
                
                // check: previous notify
                await notifyDataManager.addNotify(previousNotify)
                
            // check: new candidate
            } else {
                let userProgress = getUserProgressForChallengeNotify(with: challenge.type)
                if challenge.goal <= userProgress {
                    print("add new notify about challenge")
                    await notifyDataManager.addNewNotify(
                        createChallengeNotify(data: challenge, type: .canAchieve, date: today)
                    )
                }
            }
        }
        return true
    }
    
    private func createChallengeNotify(data: ChallengeObject, type: ChallengeNoitification, date: Date) -> NotificationObject {
        return NotificationObject(
            userId: userId,
            challengeId: data.challengeId,
            challengeStatus: type,
            category: .challenge,
            title: data.title,
            desc: "도전과제가 완료되었습니다! 도전을 완료하여 물방울을 획득해주세요.",
            updateAt: date,
            isCheck: false
        )
    }
    
    //MARK: util
    
    // condition
    private func isTrucateNeed(notify: NotificationObject) -> Bool {
        
        // user check notify
        let checkExpirationDate = Calendar.current.date(byAdding: .day, value: 3, to: notify.updateAt) ?? notify.updateAt
        if notify.isCheck && checkExpirationDate < today {
            return true
        }
        
        // user uncheck notify
        let uncheckExpirationDate = Calendar.current.date(byAdding: .day, value: 7, to: notify.updateAt) ?? notify.updateAt
        if !notify.isCheck && uncheckExpirationDate < today {
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
                print("[NotifySC] Failed to apply truncate results.")
                return false
            }
        }

        if !updateNeedNotifyList.isEmpty {
            guard await applyUpdateResult(context) else {
                print("[NotifySC] Failed to apply update results.")
                return false
            }
        }

        if await !notifyDataManager.getNewNotifyList().isEmpty {
            guard await applyAddNewResult(context) else {
                print("[NotifySC] Failed to apply new additions.")
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
    
    //MARK: update
    private func applyUpdateResult(_ context: NSManagedObjectContext) async -> Bool {
        let storageResult = applyUpdateResultToStorage(context)
        if storageResult {
            await applyUpdateResultToLocal()
            return true
        } else {
            return false
        }
    }
    private func applyUpdateResultToStorage(_ context: NSManagedObjectContext) -> Bool {
        if notifyCD.updateObjectList(context, dtoList: updateNeedNotifyList) {
            return storageManager.saveContext()
        } else {
            print("[NotifySC] Failed to process update notify")
            return false
        }
    }
    
    private func applyUpdateResultToLocal() async {
        for updateDTO in updateNeedNotifyList {
            if let index = previousNotifyList.firstIndex(where: { notify in
                (updateDTO.projectId != nil && notify.projectId == updateDTO.projectId) ||
                (updateDTO.challengeId != nil && notify.challengeId == updateDTO.challengeId)
            }) {
                let targetNotify = previousNotifyList[index]
                let updatedNotify = NotificationObject(
                    userId: targetNotify.userId,
                    projectId: updateDTO.projectId,
                    projectStatus: updateDTO.newProjectStatus,
                    challengeId: updateDTO.challengeId,
                    challengeStatus: updateDTO.newChallengeStatus,
                    category: targetNotify.category,
                    title: updateDTO.newTitle ?? targetNotify.title,
                    desc: updateDTO.newDesc ?? targetNotify.desc,
                    updateAt: updateDTO.newUpdateAt ?? targetNotify.updateAt,
                    isCheck: updateDTO.isCheck ?? targetNotify.isCheck
                )
                await notifyDataManager.addNotify(updatedNotify)
            }
        }
    }
}

//MARK: ----- Util -----

extension NotificationService {
    
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
        case .explode:
            return "결국 그날이 오고 말았습니다... 목표는 한 줌의 재가되어 사라졌습니다..."
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
            print("[NotifySC] Failed to calculate project period")
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
