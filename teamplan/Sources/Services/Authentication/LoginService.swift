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
    private var registLimit: Int
    
    private init(userId: String){
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
        self.loginDate = Date()
        self.userTerm = 0
        self.registLimit = 0
    }
    
    static func initService(with userId: String) -> LoginService {
        return LoginService(userId: userId)
    }
    
    func executor() -> Bool {
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
        return updateProcess(context)
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
            self.registLimit = coreValueCD.object.todoRegistLimit
            return true
            
        } catch{
            print("[LoginSC] Failed to preprocessing coreValue: \(error.localizedDescription)")
            return false
        }
    }
}

// MARK: Update Properties

extension LoginService {
    
    // main
    private func updateProcess(_ context: NSManagedObjectContext) -> Bool {
        var results = [Bool]()
        
        return context.performAndWait{
            results = [
                updateServiceTerm(context),
                updateLoginAt(context, with: loginDate),
                resetDailyRegistTodo(context)
            ]
            if results.allSatisfy({$0}){
                guard storageManager.saveContext() else {
                    print("[LoginLoading] Failed to apply daily update at storage")
                    return false
                }
                print("[LoginLoading] Successfully apply daily update at storage")
                return true
            }
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
    
    private func updateLoginAt(_ context: NSManagedObjectContext, with loginDate: Date) -> Bool {
        let log = AccessLog(userId: userId, accessDate: loginDate)
        guard accessLogCD.setObject(context: context, object: log) else {
            print("[LoginLoading] Failed to regist new accesslog")
            return false
        }
        return true
    }
    
    private func resetDailyRegistTodo(_ context: NSManagedObjectContext) -> Bool {
        var updatedProjectCount: Int = 0
        let projectList: [ProjectObject]
        
        do {
            // fetch projectData
            guard try projectCD.getValidObjects(context: context, with: userId) else {
                print("[LoginLoading] Failed to search projectList")
                return false
            }
            
            // projectList check
            if projectCD.objectList.isEmpty {
                print("[LoginLoading] There is no project to update")
                return true
            } else {
                projectList = projectCD.objectList
            }
            
            // update projectList
            for project in projectList {
                let updated = ProjectUpdateDTO(
                    projectId: project.projectId,
                    userId: userId,
                    newDailyRegistedTodo: registLimit
                )
                guard try projectCD.updateObject(context: context, with: updated) else {
                    print("[LoginLoading] Failed to update project \(project.projectId)")
                    return false
                }
                updatedProjectCount += 1
            }
            print("[LoginLoading] Updated Project (DailyTodoRegistLimit) : \(updatedProjectCount)")
            return true
            
        } catch {
            print("[LoginLoading] Failed to reset daily registred todo process: \(error.localizedDescription)")
            return false
        }
    }
}
