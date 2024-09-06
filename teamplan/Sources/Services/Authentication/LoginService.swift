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
    private let projectSC: ProjectService
    
    private let notifySC: NotificationService
    
    private let util: Utilities
    private let voltManager: VoltManager
    private let storageManager: LocalStorageManager
    
    private var userId: String
    private var loginDate: Date
    private var userTerm: Int
    private var registLimit: Int
    private var projectList: [ProjectObject]
    private var statData: StatisticsObject
    
    private init(userId: String){
        self.userCD = UserServicesCoredata()
        self.statCD = StatisticsServicesCoredata()
        self.challengeCD = ChallengeServicesCoredata()
        self.accessLogCD = AccessLogServicesCoredata()
        self.coreValueCD = CoreValueServicesCoredata()
        self.projectCD = ProjectServicesCoredata()
        self.projectSC = ProjectService(userId: userId)
        
        self.notifySC = NotificationService(userId: userId)
        
        self.util = Utilities()
        self.voltManager = VoltManager.shared
        self.storageManager = LocalStorageManager.shared
        
        self.userId = userId
        self.loginDate = Date()
        self.userTerm = 0
        self.registLimit = 0
        self.projectList = []
        self.statData = StatisticsObject()
    }
    
    static func initService(with userId: String) -> LoginService {
        return LoginService(userId: userId)
    }
    
    // MARK: Main
    
    func executor() async -> Bool {
        let context = storageManager.context
        
        guard checkData(context) else {
            print("[LoginLoading] There is no userData")
            return false
        }
        
        if isReloginUser(context) {
            return true
        }
        
        guard fetchData(context) else {
            print("[LoginLoading] Failed to fetch userData")
            return false
        }
        
        guard updateProcess(context) else {
            print("[LoginLoading] Failed to update properties")
            return false
        }
        
        guard await notifySC.firstLoginExecutor() else {
            print("[LoginLoading] Failed to prepare notifyData")
            return false
        }
        return true
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
                print("[LoginLoading] Failed to convert Accesslog Data")
                return false
            }
            let log = accessLogCD.object
            return util.compareTime(currentTime: loginDate, lastTime: log.accessRecord)
        } catch {
            print("[LoginLoading] Failed to get Accesslog Data: \(error.localizedDescription)")
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
                fetchCoreValueData(context)
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
            self.registLimit = coreValueCD.object.todoRegistLimit
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
        var notifyResult = false
        
        context.performAndWait {
            results = [
                updateServiceTerm(context),
                updateLoginAt(context, with: loginDate)
            ]
        }
        if results.allSatisfy({$0}) && updateProjectStatus(context) {
            guard storageManager.saveContext() else {
                print("[LoginLoading] Failed to apply daily update at storage")
                return false
            }
            return true
        } else {
            print("[LoginLoading] Daily update process failed")
            return false
        }
    }
    
    // stat
    private func updateServiceTerm(_ context: NSManagedObjectContext) -> Bool {
        let updated = StatUpdateDTO(userId: userId, newTerm: userTerm + 1)
        do {
            guard try statCD.updateObject(context: context, dto: updated) else {
                print("[LoginLoading] failed to detect update about serviceTerm")
                return false
            }
            return true
        } catch {
            print("[LoginLoading] Failed to update service Term: \(error.localizedDescription)")
            return false
        }
    }
    
    // accesslog
    private func updateLoginAt(_ context: NSManagedObjectContext, with loginDate: Date) -> Bool {
        let log = AccessLog(userId: userId, accessDate: loginDate)
        guard accessLogCD.setObject(context: context, object: log) else {
            print("[LoginLoading] Failed to regist new accesslog")
            return false
        }
        return true
    }
    
    // project
    private func updateProjectStatus(_ context: NSManagedObjectContext) -> Bool {
        
        if projectList.isEmpty {
            print("[LoginLoading] There is no project to update")
            return true
        }
        
        var explodeList: [Int] = []
        var projectUpdateList: [ProjectUpdateDTO] = []
        var totalAlertedProjects: Int = statData.totalAlertedProjects
        
        for project in projectList {
            let projectStatus = identifyProject(with: project)
            
            switch projectStatus {
                
            // alert count
            case .nearDeadline, .oneDayLeft:
                projectUpdateList.append(
                    ProjectUpdateDTO(projectId: project.projectId, userId: userId, newDailyRegistedTodo: registLimit)
                )
                totalAlertedProjects += 1
                
            // explode
            case .explode:
                explodeList.append(project.projectId)
                
            // ongoing
            default:
                projectUpdateList.append(
                    ProjectUpdateDTO(projectId: project.projectId, userId: userId, newDailyRegistedTodo: registLimit)
                )
            }
        }
        
        do {
            if !projectUpdateList.isEmpty {
                for updated in projectUpdateList {                
                    guard try projectCD.updateObject(context: context, with: updated) else {
                        print("[LoginLoading] Failed to update project \(updated.projectId)")
                        return false
                    }
                }
            }
            
            if totalAlertedProjects != statData.totalAlertedProjects {
                guard try statCD.updateObject(context: context, dto: StatUpdateDTO(userId: userId, newTotalAlertedProjects: totalAlertedProjects)) else {
                    print("[LoginLoading] Failed to update statData")
                    return false
                }
            }
            
            if !explodeList.isEmpty {
                for projectId in explodeList {
                    guard projectSC.processExplodedProject(context, with: projectId, on: loginDate) else {
                        print("[LoginLoading] Failed to process explode project")
                        return false
                    }
                }
            }
            return true
            
        } catch {
            print("[LoginLoading] Failed to process data: \(error.localizedDescription)")
            return false
        }
    }
}

extension LoginService {
    
    private func identifyProject(with object: ProjectObject) -> ProjectNotification {
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
            print("[NotifyService] Failed to calculate project period")
            return .unknown
        }
    }
}
