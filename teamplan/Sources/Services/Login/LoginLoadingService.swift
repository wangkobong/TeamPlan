//
//  LoginLoadService.swift
//  teamplan
//
//  Created by 주찬혁 on 11/21/23.
//  Copyright © 2023 team1os. All rights reserved.
//

import CoreData
import Foundation

final class LoginLoadingService{
    
    //MARK: Properties
    
    // shared
    var userData: UserInfoDTO
    var isValidUser: Bool = true
    
    // private
    private let userCD = UserServicesCoredata()
    private let statCD = StatisticsServicesCoredata()
    private let challengeCD = ChallengeServicesCoredata()
    private let accessLogCD = AccessLogServicesCoredata()
    private let coreValueCD = CoreValueServicesCoredata()
    private let projectCD = ProjectServicesCoredata()
    private let loginSC = LoginService()
    
    private var localSync: LocalSynchronize
    private var serverSync: ServerSynchronize
    
    private var userId: String
    private var loginDate: Date
    private var userTerm: Int
    private var syncTerm: Int
    private var registLimit: Int
    private var updateType: UpdateType
    
    private let util = Utilities()
    private let storageManager: LocalStorageManager
    
    private init(userId: String){
        self.loginDate = Date()
        self.userId = userId
        
        self.userTerm = 0
        self.syncTerm = 0
        self.registLimit = 0
        
        self.userData = UserInfoDTO()
        
        self.updateType = .unknown
        self.localSync = LocalSynchronize(with: userId)
        self.serverSync = ServerSynchronize(with: userId)
        self.storageManager = LocalStorageManager.shared
    }

    static func createInstance(with dto: AuthSocialLoginResDTO) async -> LoginLoadingService {
        return LoginLoadingService(userId: dto.identifier)
    }
}

//MARK: Main Executor

enum LoginLoadingServiceAction: String {
    case checkData = "checkData"
    case fetchDataFromServer = "fetchDataFromServer"
    case isReloginUser = "isReloginUser"
    case prepareServiceData = "prepareServiceData"
    case prepareReturnData = "prepareReturnData"
    case excuteUpdate = "excuteUpdate"
}

extension LoginLoadingService {
    
    // Main controller
    func executor() async -> Bool {
        
        // 1. Inspect local data
        if await !executeServiceAction(.checkData) {
            if await !executeServiceAction(.fetchDataFromServer){
                if await resetUserStatus() {
                    print("[LoginLoadingService] Successfully truncate unstable userData")
                } else {
                    print("[LoginLoadingService] Failed to truncate unstable userData")
                }
                return false
            }
        }
        
        // 2. check re-login user
        if await executeServiceAction(.isReloginUser) {
            return await executeServiceAction(.prepareReturnData)
        }
        
        // 3. prepare userData
        let isUpdateDataReady = await executeServiceAction(.prepareServiceData)
        let isUpdateProcessed = await executeServiceAction(.excuteUpdate)
        let isUserInfoReady = await executeServiceAction(.prepareReturnData)
        
        return isUpdateDataReady && isUpdateProcessed && isUserInfoReady
    }
    
    // service action
    private func executeDetailAction(_ action: LoginLoadingServiceAction) async -> Bool {
        let context = storageManager.context
        
        switch action {
        case .checkData:
            return checkData(context: context)
        case .fetchDataFromServer:
            return await fetchDataFromServer()
        case .isReloginUser:
            return filteringUser(context: context)
        case .prepareServiceData:
            return prepareServiceData(context: context)
        case .prepareReturnData:
            return prepareReturnData(context: context)
        case .excuteUpdate:
            await decideUpdateType()
            return await updateExecutor(context: context)
        }
    }
}

// MARK: Inspect local data

enum CheckCase {
    case user
    case stat
    case coreValue
    case accessLog
    case challenge
}

extension LoginLoadingService{
    
    /// 로컬에 필요한 모든 데이터가 존재하는지 확인합니다.
    /// - Returns: 모든 데이터(사용자, 통계정보, 접속 로그, 도전과제 로그)가 존재하면 true, 그렇지 않으면 false를 반환합니다.
    private func checkData(context: NSManagedObjectContext) -> Bool {
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
    
    // MARK: - Check Re-Login User
    
    /// 이전 로그인 시간과 현재 시간을 비교하여 사용자를 필터링합니다. 사용자는 당일 첫 로그인 사용자와 재로그인 사용자로 나뉩니다.
    /// - Returns: 재로그인 사용자는  true, 당일 첫 로그인 사용자는 false를 반환합니다.
    /// - Throws: `LoginLoadingServiceError.EmptyAccessLog` 접속로그가 비어 있을 경우 발생합니다.
    private func filteringUser(context: NSManagedObjectContext) -> Bool {
        do {
            guard try accessLogCD.getLatestObject(context: context, userId: userId) else {
                print("[LoginLoading] Failed to convert Accesslog Data")
                return false
            }
            let log = accessLogCD.object
            return util.compareTime(currentTime: loginDate, lastTime: log.accessRecord)
        } catch {
            print("[LoginLoading] Failed to get Accesslog Data: \(error)")
            return false
        }
    }
}

// MARK: - Update Executor

enum UpdateType {
    case unknown
    case daily
    case weekly
    case monthly
    case quarterly
}

extension LoginLoadingService {
    
    // Update Sorter
    // : Based on ServiceTerm
    private func decideUpdateType() async {

        if userTerm % 90 == 0 {
            updateType = .quarterly
        } else if userTerm % 30 == 0 {
            updateType = .monthly
        } else if userTerm % 7 == 0 {
            updateType = .weekly
        } else {
            updateType = .daily
        }
    }
    
    private func updateExecutor(context: NSManagedObjectContext) async -> Bool {
        switch self.updateType {
        case .unknown:
            print("[LoginLoading] Unknown userType detected!")
            return false
        case .daily:
            return dailyUpdateProcess(context: context)
        case .weekly:
            return await weeklyUpdateProcess(context: context)
        case .monthly:
            return await monthlyUpdateProcess(context: context)
        case .quarterly:
            return await quarterlyUpdateProcess(context: context)
        }
    }
    
    //MARK: Daily Update
    
    private func dailyUpdateProcess(context: NSManagedObjectContext) -> Bool {
        var results = [Bool]()
        
        return context.performAndWait{
            results = [
                updateServiceTerm(context: context),
                updateLoginAt(context: context, with: loginDate),
                resetDailyRegistTodo(context: context)
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
    
    //MARK: Weekly Update
    
    private func weeklyUpdateProcess(context: NSManagedObjectContext) async -> Bool {
        let isDailyUpdateProcessed = dailyUpdateProcess(context: context)
        let isServerDataUpdated = await updateDataAtServer(.weekly, at: loginDate)
        
        if isDailyUpdateProcessed && isServerDataUpdated {
            print("[LoginLoading] Successfully process Weekly update")
            return true
        } else {
            print("[LoginLoading] Weekly update process failed")
            return false
        }
    }
    
    //MARK: Monthly Update
    
    private func monthlyUpdateProcess(context: NSManagedObjectContext) async -> Bool {
        let isDailyUpdateProcessed = dailyUpdateProcess(context: context)
        let isServerDataUpdated = await updateDataAtServer(.monthly, at: loginDate)
        
        if isDailyUpdateProcessed && isServerDataUpdated {
            print("[LoginLoading] Successfully process monthly update")
            return true
        } else {
            print("[LoginLoading] Monthly update process failed")
            return false
        }
    }
    
    //MARK: Quarterly Update
    
    private func quarterlyUpdateProcess(context: NSManagedObjectContext) async -> Bool {
        let isDailyUpdateProcessed = dailyUpdateProcess(context: context)
        let isQuarterlyUpdatedProcessed = await updateDataAtServer(.quarterly, at: loginDate)
        
        if isDailyUpdateProcessed && isQuarterlyUpdatedProcessed {
            print("[LoginLoading] Successfully process Quarterly update")
            return true
        } else {
            print("[LoginLoading] Quarterly update process failed")
            return false
        }
    }
}

// MARK: - Synchronizer

extension LoginLoadingService {
    
    private func fetchDataFromServer() async -> Bool {
        if await localSync.syncExecutor() {
            print("[LoginLoading] Succesfully Reset local data")
            return true
        } else {
            print("[LoginLoading] Failed to fetch data from server")
            return false
        }
    }
    
    private func updateDataAtServer(_ type: SyncType, at syncDate: Date) async -> Bool {
        if await serverSync.syncExecutor(type, with: syncDate) {
            print("[LoginLoading] Succesfully Synchronize server with local")
            return true
        } else {
            print("[LoginLoading] Failed to synchronize server with local")
            return false
        }
    }
}

// MARK: - Util

extension LoginLoadingService {

    // prepare: data for service
    private func prepareServiceData(context: NSManagedObjectContext) -> Bool {
        
        return context.performAndWait {
            do {
                let isStatDataReady = try statCD.getObject(context: context, userId: userId)
                let isCoreValueReady = try coreValueCD.getObject(context: context, userId: userId)
                
                if isStatDataReady && isCoreValueReady {
                    self.userTerm = statCD.object.term
                    self.syncTerm = coreValueCD.object.syncCycle
                    self.registLimit = coreValueCD.object.todoRegistLimit
                    return true
                } else {
                    print("[LoginLoading] Failed to fetch Statistics & CoreValue from localStorage")
                    return false
                }
            } catch {
                print("[LoginLoading] Prepare service data process failed: \(error.localizedDescription)")
                return false
            }
        }
    }
    
    // prepare: data for return
    private func prepareReturnData(context: NSManagedObjectContext) -> Bool {
        
        return context.performAndWait{
            do {
                guard try userCD.getObject(context: context, userId: userId) else {
                    print("[LoginLoading] Failed to fetch userData from localStorage")
                    return false
                }
                self.userData = UserInfoDTO(with: userCD.object)
                return true
                
            } catch {
                print("[LoginLoading] Prepare UserData process failed: \(error.localizedDescription)")
                return false
            }
        }
    }
    
    // executor: buffer
    private func executeServiceAction(_ action: LoginLoadingServiceAction) async -> Bool {
        return await retryServiceExecutor(action)
    }
    
    // executor: re-try
    private func retryServiceExecutor(_ action: LoginLoadingServiceAction) async -> Bool {
        let max = 3
        var retryCount = 1
        var isProcessComplete = false
        
        while retryCount <= max && !isProcessComplete {
            isProcessComplete = await executeDetailAction(action)
            
            if !isProcessComplete {
                print("[LoginLoading] Retrying '\(action.rawValue)' action... \(retryCount)/\(max)")
                retryCount += 1
            }
        }
        if !isProcessComplete {
            print("[LoginLoading] Failed to execute '\(action.rawValue)' action after \(max) retries")
            return false
        }
        print("[LoginLoading] Successfully executed '\(action.rawValue)' action in \(retryCount) tries")
        return true
    }
    
    // update: serviceTerm
    private func updateServiceTerm(context: NSManagedObjectContext) -> Bool {
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
    
    // update: accessLog
    private func updateLoginAt(context: NSManagedObjectContext, with loginDate: Date) -> Bool {
        let log = AccessLog(userId: userId, accessDate: loginDate)
        guard accessLogCD.setObject(context: context, object: log) else {
            print("[LoginLoading] Failed to regist new accesslog")
            return false
        }
        return true
    }
    
    // update: dailyRegistTodo
    private func resetDailyRegistTodo(context: NSManagedObjectContext) -> Bool {
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
    
    // truncate unstable userData
    private func resetUserStatus() async -> Bool {
        
        self.isValidUser = false
        return await loginSC.withdrawUser()
    }
}
    
// MARK: - Return DTO

struct UserInfoDTO {
    
    let userId: String
    let email: String
    let nickName: String
    let socialType: Providers
    let status: UserStatus
    let changedAt: Date
    
    init(){
        self.userId = "Unknown"
        self.email = "Unknown"
        self.nickName = "Unknown"
        self.socialType = .unknown
        self.status = .unknown
        self.changedAt = Date()
    }
    init(with object: UserObject){
        self.userId = object.userId
        self.email = object.email
        self.nickName = object.name
        self.socialType = object.socialType
        self.status = object.status
        self.changedAt = object.changedAt
    }
}
