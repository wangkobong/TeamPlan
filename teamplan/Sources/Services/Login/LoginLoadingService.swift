//
//  LoginLoadService.swift
//  teamplan
//
//  Created by 주찬혁 on 11/21/23.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation

final class LoginLoadingService{
    
    // shared
    var userData: UserInfoDTO
    
    // private
    private let userCD = UserServicesCoredata()
    private let statCD = StatisticsServicesCoredata()
    private let challengeCD = ChallengeServicesCoredata()
    private let accessLogCD = AccessLogServicesCoredata()
    private let coreValueCD = CoreValueServicesCoredata()
    private let projectCD = ProjectServicesCoredata()
    
    private var syncLocalWithServer: SyncLocalWithServer
    private var syncServerWithLocal: SyncServerWithLocal
    
    private var userId: String
    private var loginDate: Date
    private var userTerm: Int
    private var syncTerm: Int
    private var updateType: UpdateType
    
    private let util = Utilities()
    private let coreValue: CoreValueObject
    
    init(){
        self.loginDate = Date()
        self.userId = "Unknown"
        self.userData = UserInfoDTO()
        self.userTerm = 0
        self.syncTerm = 0
        self.updateType = .unknown
        
        self.coreValue = CoreValueObject()
        self.syncLocalWithServer = SyncLocalWithServer(with: userId)
        self.syncServerWithLocal = SyncServerWithLocal(with: userId)
    }


    
    private func prepareBasicData(with dto: AuthSocialLoginResDTO) async {
        self.loginDate = Date()
        self.userId = dto.identifier
    }
    
    private func prepareUpdateData() async -> Bool {
        do {
            self.userTerm = try statCD.getObject(with: userId).term
            self.syncTerm = try coreValueCD.getObject(with: userId).syncCycle
            return true
        } catch {
            print("[LoginLoading] Failed to fetch Statistics & CoreValue from localStorage")
            return false
        }
    }
    
    private func prepareUserData() async -> Bool {
        do {
            let userData = try userCD.getObject(with: userId)
            self.userData = UserInfoDTO(with: userData)
            return true
        } catch {
            print("[LoginLoading] Failed to fetch userData from localStorage")
            return false
        }
    }
}

//MARK: Executor

enum LoginLoadingServiceAction: String {
    case checkData = "checkData"
    case fetchDataFromServer = "fetchDataFromServer"
    case isReloginUser = "isReloginUser"
    case prepareUpdateData = "prepareUpdateData"
    case prepareUserData = "prepareUserData"
    case excuteUpdate = "excuteUpdate"
}

extension LoginLoadingService {
    
    func executor(with dto: AuthSocialLoginResDTO) async -> Bool {
        
        await prepareBasicData(with: dto)
        
        // check: local data
        if await !executeServiceAction(.checkData) {
            _ = await executeServiceAction(.fetchDataFromServer)
        }
        
        // check: relogin user
        if await executeServiceAction(.isReloginUser) {
            return await executeServiceAction(.prepareUserData)
        }
        
        let isUpdateDataReady = await executeServiceAction(.prepareUpdateData)
        let isUpdateProcessed = await executeServiceAction(.excuteUpdate)
        let isUserInfoReady = await executeServiceAction(.prepareUserData)
        
        return isUpdateDataReady && isUpdateProcessed && isUserInfoReady
    }
    
    private func executeServiceAction(_ action: LoginLoadingServiceAction) async -> Bool {
        return await retryServiceExecutor(action)
    }
    
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
    
    private func executeDetailAction(_ action: LoginLoadingServiceAction) async -> Bool {
        switch action {
        case .checkData:
            return await checkData()
        case .fetchDataFromServer:
            return await fetchDataFromServer()
        case .isReloginUser:
            return await filteringUser()
        case .prepareUpdateData:
            return await prepareUpdateData()
        case .prepareUserData:
            return await prepareUserData()
        case .excuteUpdate:
            await decideUpdateType()
            return await updateExecutor()
        }
    }
}


// MARK: - Return Type
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


// MARK: - Data Check
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
        
        let results = await [isUserDataExist, isStatDataExist, isCoreValueExist, isAccessLogExist, isChallengeDataExist]
        return results.allSatisfy { $0 }
    }
    
    // MARK: - Filiter
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
    // Test: Erase All Local Data
    private func resetLocalData() throws {
        try userCD.deleteObject(with: userId)
        try statCD.deleteObject(with: userId)
        try coreValueCD.deleteObject(with: userId)
        try challengeCD.deleteObject(with: userId)
        try accessLogCD.deleteObject(with: userId)
    }
}


// MARK: - Sync with Server
extension LoginLoadingService {
    
    private func fetchDataFromServer() async -> Bool {
        do {
            try await syncLocalWithServer.syncExecutor(with: userId)
            print("[LoginLoading] Succesfully fetch data from server")
            return true
        } catch {
            print("[LoginLoading] Failed to fetch data from server")
            return false
        }
    }
    
    private func updateDataAtServer(at syncDate: Date) async -> Bool {
        do {
            try await syncServerWithLocal.syncExecutor(with: userId, and: syncDate)
            print("[LoginLoading] Succesfully Synchronize with Server")
            return true
        } catch {
            print("[LoginLoading] Synchronize with Server Failed")
            return false
        }
    }
}


// MARK: - Update
enum UpdateType {
    case unknown
    case daily
    case weekly
    case quarterly
}
extension LoginLoadingService {
    
    // Update Sorter
    // : Based on ServiceTerm
    private func decideUpdateType() async {
        if userTerm % 90 == 0 {
            updateType = .weekly
        } else if userTerm % self.syncTerm == 0 {
            updateType = .quarterly
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
            return await dailyUpdateProcess(with: loginDate)
        case .weekly:
            return await weeklyUpdateProcess()
        case .quarterly:
            return await quarterlyUpdateProcess()
        }
    }
    
    //MARK: Daily Update
    
    // executor
    private func dailyUpdateProcess(with loginDate: Date) async -> Bool {
        async let isServiceTermUpdated = updateServiceTerm()
        async let isAccessLogUpdated = updateLoginAt(with: loginDate)
        async let isProjectReset = resetDailyRegistTodo()
        
        let results = await [isServiceTermUpdated, isAccessLogUpdated, isProjectReset]
        if results.allSatisfy({ $0 }) {
            print("[LoginLoading] Successfully process Daily update")
            return true
        } else {
            print("[LoginLoading] Daily Update Failed")
            return false
        }
    }
    
    // update: 서비스 사용기간
    private func updateServiceTerm() async -> Bool {
        let updated = StatUpdateDTO(userId: userId, newTerm: userTerm + 1)
        do {
            try statCD.updateObject(with: updated)
            return true
        } catch {
            print("[LoginLoading] Failed to update service Term")
            return false
        }
    }
    
    // update: 접속로그
    private func updateLoginAt(with loginDate: Date) async -> Bool {
        let log = AccessLog(userId: userId, accessDate: loginDate)
        do {
            try accessLogCD.setObject(with: log)
            return true
        } catch {
            print("[LoginLoading] Failed to update AccessLog")
            return false
        }
    }
    
    // update: 최대 할 일 등록개수
    private func resetDailyRegistTodo() async -> Bool {
        let projectIdList: [Int]
        
        do {
            projectIdList = try projectCD.getIdList(with: userId)
        } catch {
            print("[LoginLoading] Failed to search projectList")
            return false
        }
        
        var allUpdated = true
        for projectId in projectIdList {
            let updated = ProjectUpdateDTO(
                projectId: projectId,
                userId: userId,
                newDailyRegistedTodo: coreValue.todoRegistLimit
            )
            do {
                try projectCD.updateObject(with: updated)
            } catch {
                print("[LoginLoading] Failed to update project \(projectId)")
                allUpdated = false
            }
        }
        return allUpdated
    }
    
    //MARK: Weekly Update
    
    // executor
    private func weeklyUpdateProcess() async -> Bool {
        let isDailyUpdateSuccess = await dailyUpdateProcess(with: loginDate)
        let isServerDataUpdated = await updateDataAtServer(at: loginDate)
        
        if isDailyUpdateSuccess && isServerDataUpdated {
            print("[LoginLoading] Successfully process Weekly update")
            return true
        } else {
            print("[LoginLoading] Weekly update process failed")
            return false
        }
    }
    
    //MARK: Quarterly Update
    
    // executor
    private func quarterlyUpdateProcess() async -> Bool {
        let isDailyUpdateProcessed = await dailyUpdateProcess(with: loginDate)
        let isLogHeadUpdated = await updateLogHead()
        let isWeeklyUpdatedProcessed = await weeklyUpdateProcess()
        
        if isDailyUpdateProcessed && isLogHeadUpdated && isWeeklyUpdatedProcessed {
            print("[LoginLoading] Successfully process Quarterly update")
            return true
        } else {
            print("[LoginLoading] Quarterly update process failed")
            return false
        }
    }
    
    // update: logHead
    private func updateLogHead() async -> Bool {
        let user: UserObject
        
        // fetch data
        do {
            user = try userCD.getObject(with: userId)
        } catch {
            print("[LoginLoading] Failed to get userData at localStorage")
            return false
        }
        // update
        do {
            let updated = UserUpdateDTO(userId: userId, newLogHead: user.accessLogHead + 1)
            try userCD.updateObject(with: updated)
            return true
        } catch {
            print("[LoginLoading] Failed update userData at localStorage")
            return false
        }
    }
}

