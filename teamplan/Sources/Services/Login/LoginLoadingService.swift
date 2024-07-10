//
//  LoginLoadService.swift
//  teamplan
//
//  Created by 주찬혁 on 11/21/23.
//  Copyright © 2023 team1os. All rights reserved.
//

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
    
    private init(userId: String){
        self.loginDate = Date()
        self.userId = userId
        self.userData = UserInfoDTO()
        self.userTerm = 0
        self.syncTerm = 0
        self.registLimit = 0
        self.updateType = .unknown
    
        self.localSync = LocalSynchronize(with: userId)
        self.serverSync = ServerSynchronize(with: userId)
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
        switch action {
        case .checkData:
            return await checkData()
        case .fetchDataFromServer:
            return await fetchDataFromServer()
        case .isReloginUser:
            return await filteringUser()
        case .prepareServiceData:
            return await prepareServiceData()
        case .prepareReturnData:
            return await prepareReturnData()
        case .excuteUpdate:
            await decideUpdateType()
            return await updateExecutor()
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
    private func checkData() async -> Bool {
        async let isUserDataExist = userCD.isObjectExist(with: userId)
        async let isStatDataExist = statCD.isObjectExist(with: userId)
        async let isCoreValueExist = coreValueCD.isObjectExist(with: userId)
        async let isAccessLogExist = accessLogCD.isObjectExist(with: userId)
        async let isChallengeDataExist = challengeCD.isObjectExist(with: userId)
        
        let results = await [
            isUserDataExist,
            isStatDataExist,
            isCoreValueExist,
            isAccessLogExist,
            isChallengeDataExist
        ]
        return results.allSatisfy { $0 }
    }
    
    // MARK: - Check Re-Login User
    
    /// 이전 로그인 시간과 현재 시간을 비교하여 사용자를 필터링합니다. 사용자는 당일 첫 로그인 사용자와 재로그인 사용자로 나뉩니다.
    /// - Returns: 재로그인 사용자는  true, 당일 첫 로그인 사용자는 false를 반환합니다.
    /// - Throws: `LoginLoadingServiceError.EmptyAccessLog` 접속로그가 비어 있을 경우 발생합니다.
    private func filteringUser() async -> Bool {
        do {
            let log = try accessLogCD.getLatestObject(with: userId)
            return util.compareTime(currentTime: loginDate, lastTime: log.accessRecord)
        } catch {
            print("[LoginLoading] Failed to get Accesslog Data")
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
    
    private func updateExecutor() async -> Bool {
        switch self.updateType {
        case .unknown:
            print("[LoginLoading] Unknown userType detected!")
            return false
        case .daily:
            return await dailyUpdateProcess()
        case .weekly:
            return await weeklyUpdateProcess()
        case .monthly:
            return await monthlyUpdateProcess()
        case .quarterly:
            return await quarterlyUpdateProcess()
        }
    }
    
    //MARK: Daily Update
    
    private func dailyUpdateProcess() async -> Bool {
        async let isServiceTermUpdated = updateServiceTerm()
        async let isAccessLogUpdated = updateLoginAt(with: loginDate)
        async let isProjectReset = resetDailyRegistTodo()
        
        let results = await [isServiceTermUpdated, isAccessLogUpdated, isProjectReset]
        
        if results.allSatisfy({ $0 }) {
            if await LocalStorageManager.shared.saveContext(){
                print("[LoginLoading] Successfully process Daily update")
                return true
            } else {
                print("[LoginLoading] Failed to update context")
                return false
            }
        } else {
            print("[LoginLoading] Daily Update Failed")
            return false
        }
    }
    
    //MARK: Weekly Update
    
    private func weeklyUpdateProcess() async -> Bool {
        let isDailyUpdateProcessed = await dailyUpdateProcess()
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
    
    private func monthlyUpdateProcess() async -> Bool {
        let isDailyUpdateProcessed = await dailyUpdateProcess()
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
    
    private func quarterlyUpdateProcess() async -> Bool {
        let isDailyUpdateProcessed = await dailyUpdateProcess()
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
    private func prepareServiceData() async -> Bool {
        do {
            let coreValue = try coreValueCD.getObject(with: userId)
            self.userTerm = try statCD.getObject(with: userId).term
            self.registLimit = coreValue.todoRegistLimit
            self.syncTerm = coreValue.syncCycle
            return true
        } catch {
            print("[LoginLoading] Failed to fetch Statistics & CoreValue from localStorage")
            return false
        }
    }
    
    // prepare: data for return
    private func prepareReturnData() async -> Bool {
        do {
            let userData = try userCD.getObject(with: userId)
            self.userData = UserInfoDTO(with: userData)
            return true
        } catch {
            print("[LoginLoading] Failed to fetch userData from localStorage")
            return false
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
    private func updateServiceTerm() async -> Bool {
        let updated = StatUpdateDTO(userId: userId, newTerm: userTerm + 1)
        do {
            return try statCD.updateObject(with: updated)
        } catch {
            print("[LoginLoading] Failed to update service Term")
            return false
        }
    }
    
    // update: accessLog
    private func updateLoginAt(with loginDate: Date) async -> Bool {
        let log = AccessLog(userId: userId, accessDate: loginDate)
        if accessLogCD.setObject(with: log) {
            print("[LoginLoading] Successfully regist new accesslog")
            return true
        } else {
            print("[LoginLoading] Failed to regist new accesslog")
            return false
        }
    }
    
    // update: dailyRegistTodo
    private func resetDailyRegistTodo() async -> Bool {
        var updatedProjectCount: Int = 0
        let projectIdList: [Int]
        
        do {
            projectIdList = try projectCD.getIdList(with: userId)
        } catch {
            print("[LoginLoading] Failed to search projectList")
            return false
        }
        
        if projectIdList.isEmpty {
            print("[LoginLoading] There is no project to update")
            return true
        }
        
        for projectId in projectIdList {
            let updated = ProjectUpdateDTO(
                projectId: projectId,
                userId: userId,
                newDailyRegistedTodo: registLimit
            )
            do {
                if try projectCD.updateObject(with: updated) {
                    updatedProjectCount += 1
                }
            } catch {
                print("[LoginLoading] Failed to update project \(projectId)")
                return false
            }
        }
        print("[LoginLoading] Updated Project (DailyTodoRegistLimit) : \(updatedProjectCount)")
        return true
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
