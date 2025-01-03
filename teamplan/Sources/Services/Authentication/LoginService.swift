//
//  LoginService.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/09/06.
//  Copyright © 2023 team1os. All rights reserved.
//

import CoreData
import Foundation

final class LoginService{
    
    private let userCD: UserServicesCoredata
    private let statCD: StatisticsServicesCoredata
    private let challengeCD: ChallengeServicesCoredata
    private let accessLogCD: AccessLogServicesCoredata
    private let coreValueCD: CoreValueServicesCoredata
    private let projectCD: ProjectServicesCoredata
    
    private let util: Utilities
    private let voltManager: VoltManager
    private let storageManager: LocalStorageManager
    
    private var userId: String
    private var loginDate: Date
    private var userTerm: Int
    private var statData: StatisticsObject
    
    private var todoRegistLimit: Int
    private var projectList: [ProjectObject]
    private var projectUpdateList: [ProjectUpdateDTO]
    private var projectExplodeList: [Int]
    private var projectAlertCount: Int
    private var projectExplodeCount: Int
    
    private init(userId: String, loginDate: Date = Date()){
        self.userCD = UserServicesCoredata()
        self.statCD = StatisticsServicesCoredata()
        self.challengeCD = ChallengeServicesCoredata()
        self.accessLogCD = AccessLogServicesCoredata()
        self.coreValueCD = CoreValueServicesCoredata()
        self.projectCD = ProjectServicesCoredata()
        
        self.util = Utilities()
        self.voltManager = VoltManager.shared
        self.storageManager = LocalStorageManager.shared
        
        self.userId = userId
        self.loginDate = loginDate
        self.userTerm = 0
        self.statData = StatisticsObject()
        
        self.todoRegistLimit = 0
        self.projectList = []
        self.projectUpdateList = []
        self.projectExplodeList = []
        self.projectAlertCount = 0
        self.projectExplodeCount = 0
    }
    
    static func initService(with userId: String) -> LoginService {
        return LoginService(userId: userId)
    }
    
    // MARK: Main
    
    func executor() async -> Bool {
        let context = storageManager.context
        
        guard checkData(context) else {
            print("[LoginSC] There is no userData")
            return false
        }
        
        if isReloginUser(context) {
            return true
        }
        
        guard fetchData(context) else {
            print("[LoginSC] Failed to fetch userData")
            return false
        }
        
        guard updateProcess(context) else {
            print("[LoginSC] Failed to update properties")
            return false
        }
        
        guard await notifyProcess() else {
            print("[LoginSC] Failed to process notifyData")
            return false
        }
        return true
    }
    
    private func notifyProcess() async -> Bool {
        let notifyService = NotificationService(
            loginDate: loginDate,
            userId: userId,
            statData: statData,
            projectList: projectList,
            statCD: statCD,
            projectCD: projectCD,
            challengeCD: challengeCD,
            storageManager: storageManager,
            util: util
        )
        return await notifyService.loginExecutor()
    }
}

// MARK: Check Data

extension LoginService {
    
    private func checkData(_ context: NSManagedObjectContext) -> Bool {
        var results = [Bool]()
        
        return context.performAndWait {
            results = [
                userCD.isObjectExist(context: context, userId: userId),
                statCD.isObjectExist(context: context, userId: userId),
                coreValueCD.isObjectExist(context: context, userId: userId),
                accessLogCD.isObjectExist(context: context, userId: userId),
                challengeCD.isObjectExist(context: context, userId: userId)
            ]
            return results.allSatisfy { $0 }
        }
    }
    
    private func isReloginUser(_ context: NSManagedObjectContext) -> Bool {
        do {
            guard try accessLogCD.getLatestObject(context: context, userId: userId) else {
                print("[LoginSC] Failed to convert Accesslog Data")
                return false
            }
            let log = accessLogCD.object
            return util.compareTime(currentTime: loginDate, lastTime: log.accessRecord)
        } catch {
            print("[LoginSC] Failed to get Accesslog Data: \(error.localizedDescription)")
            return false
        }
    }
}

// MARK: Fetch Data

extension LoginService {
    
    private func fetchData(_ context: NSManagedObjectContext) -> Bool {
        var results = [Bool]()
        
        context.performAndWait {
            results = [
                fetchStatData(context),
                fetchCoreValueData(context),
                fetchProjectData(context)
            ]
        }
        return results.allSatisfy{$0}
    }
    
    private func fetchStatData(_ context: NSManagedObjectContext) -> Bool {
        do {
            guard try statCD.getObject(context: context, userId: userId) else {
                print("[LoginSC] Failed to fetch StatData from storage")
                return false
            }
            self.statData = statCD.object
            self.userTerm = statCD.object.term
            return true
            
        } catch {
            print("[LoginSC] Failed to preprocessing StatData: \(error.localizedDescription)")
            return false
        }
    }
    
    private func fetchCoreValueData(_ context: NSManagedObjectContext) -> Bool {
        do {
            guard try coreValueCD.getObject(context: context, userId: userId) else {
                print("[LoginSC] Failed to fetch CoreValue from storage")
                return false
            }
            self.todoRegistLimit = coreValueCD.object.todoRegistLimit
            return true
            
        } catch{
            print("[LoginSC] Failed to preprocessing coreValue: \(error.localizedDescription)")
            return false
        }
    }
    
    private func fetchProjectData(_ context: NSManagedObjectContext) -> Bool {
        do {
            guard try projectCD.getTotalObjects(context: context, with: userId) else {
                print("[LoginSC] Failed to fetch ProjectData from storage")
                return false
            }
            self.projectList = projectCD.objectList
            return true
            
        } catch {
            print("[LoginSC] Failed to preprocessing project: \(error.localizedDescription)")
            return false
        }
    }
}

// MARK: Update Properties

extension LoginService {
    
    // main
    private func updateProcess(_ context: NSManagedObjectContext) -> Bool {
        var results = [Bool]()
        
        context.performAndWait {
            results = [
                updateServiceTerm(context),
                updateLoginAt(context, with: loginDate)
            ]
        }
        
        guard results.allSatisfy({$0}) && updateProjectStatus(context) else {
            print("[LoginSC] Failed to update userData")
            return false
        }
        var applyResult: Bool = false
        
        context.performAndWait {
            applyResult = storageManager.saveContext()
        }
        if applyResult {
            return true
        } else {
            print("[LoginSC] Failed to apply userData to storage")
            return false
        }
    }
    
    // stat
    private func updateServiceTerm(_ context: NSManagedObjectContext) -> Bool {
        let updated = StatUpdateDTO(userId: userId, newTerm: userTerm + 1)
        do {
            guard try statCD.updateObject(context: context, dto: updated) else {
                print("[LoginSC] failed to detect update about serviceTerm")
                return false
            }
            return true
        } catch {
            print("[LoginSC] Failed to update service Term: \(error.localizedDescription)")
            return false
        }
    }
    
    // accesslog
    private func updateLoginAt(_ context: NSManagedObjectContext, with loginDate: Date) -> Bool {
        let log = AccessLog(userId: userId, accessDate: loginDate)
        guard accessLogCD.setObject(context: context, object: log) else {
            print("[LoginSC] Failed to regist new accesslog")
            return false
        }
        return true
    }
}

//MARK: Update Project

extension LoginService {
    
    // project
    private func updateProjectStatus(_ context: NSManagedObjectContext) -> Bool {
        
        if projectList.isEmpty {
            print("[ProjectSC] There is no project to update")
            return true
        }
        
        guard distinctProjectByStatus() else {
            print("[ProjectSC] Failed to distinct project by status")
            return true
        }
        
        let updateResult = [
            ongogingProjectProcess(context),
            explodeProjectProcess(context),
            updateStatData(context)
        ]
        
        if updateResult.allSatisfy({$0}) {
            return true
        } else {
            print("[ProjectSC] Failed to update projectStatus")
            return false
        }
    }
    
    private func distinctProjectByStatus() -> Bool {
        
        for project in projectList {
            switch identifyProjectStatus(with: project) {
                
            case .nearDeadline, .oneDayLeft:
                projectUpdateList.append(
                    ProjectUpdateDTO(
                        projectId: project.projectId,
                        userId: userId,
                        newDailyRegistedTodo: todoRegistLimit
                    )
                )
                projectAlertCount += 1
                
            case .explode:
                projectExplodeList.append(project.projectId)
                projectExplodeCount += 1
                
            case .unknown:
                return false
                
            default:
                projectUpdateList.append(
                    ProjectUpdateDTO(
                        projectId: project.projectId,
                        userId: userId,
                        newDailyRegistedTodo: todoRegistLimit
                    )
                )
            }
        }
        return true
    }
    
    private func identifyProjectStatus(with object: ProjectObject) -> ProjectNotification {
        do {
            let totalPeriod = try util.calculateDatePeriod(with: object.startedAt, and: object.deadline)
            let progressedPeriod = try util.calculateDatePeriod(with: object.startedAt, and: loginDate)
            
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
            print("[LoginSC] Failed to calculate project period")
            return .unknown
        }
    }
    
    private func ongogingProjectProcess(_ context: NSManagedObjectContext) -> Bool {
        
        if projectUpdateList.isEmpty {
            print("[ProjectSC] There is no ongoing project to process")
            return true
        }
        
        var processResult: [Bool] = []
        for updated in projectUpdateList {
            let result = context.performAndWait{
                do {
                    guard try projectCD.updateObject(context: context, with: updated) else {
                        print("[ProjectSC] ProjectObject change not detected")
                        return false
                    }
                    return true
                } catch {
                    print("[ProjectSC] Failed to update ongoing project: \(error.localizedDescription)")
                    return false
                }
            }
            processResult.append(result)
        }
        return processResult.allSatisfy{$0}
    }
    
    private func explodeProjectProcess(_ context: NSManagedObjectContext) -> Bool {
        
        if projectExplodeList.isEmpty {
            print("[ProjectSC] There is no explode project to process")
            return true
        }
        
        var processResult: [Bool] = []
        for projectId in projectExplodeList {
            
            let projectUpdated = ProjectUpdateDTO(
                projectId: projectId,
                userId: userId,
                newStatus: .exploded,
                newFinishedAt: loginDate
            )
            let result = context.performAndWait {
                do {
                    guard try projectCD.updateObject(context: context, with: projectUpdated) else {
                        print("[ProjectSC] ProjectObject change not detected")
                        return false
                    }
                    return true
                } catch {
                    print("[ProjectSC] Failed to process explode project: \(error.localizedDescription)")
                    return false
                }
            }
            processResult.append(result)
        }
        return processResult.allSatisfy{$0}
    }
    
    private func updateStatData(_ context: NSManagedObjectContext) -> Bool {
        
        guard projectAlertCount > 0 || projectExplodeCount > 0 else {
            print("[ProjectSC] There is no data to update stat")
            return true
        }

        var updated = StatUpdateDTO(userId: userId)
        if projectAlertCount > 0 {
            updated.newTotalAlertedProjects = statData.totalAlertedProjects + projectAlertCount
        }
        if projectExplodeCount > 0 {
            updated.newTotalFailedProjects = statData.totalFailedProjects + projectExplodeCount
        }

        return context.performAndWait {
            do {
                guard try statCD.updateObject(context: context, dto: updated) else {
                    print("[ProjectSC] Failed to update statData")
                    return false
                }
                return true
            } catch {
                print("[ProjectSC] Error updating statData: \(error.localizedDescription)")
                return false
            }
        }
    }
    
}
