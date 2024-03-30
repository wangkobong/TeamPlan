//
//  LoginLoadService.swift
//  teamplan
//
//  Created by 주찬혁 on 11/21/23.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation

final class LoginLoadingService{
    
    private let util = Utilities()
    private let controller = CoredataController()

    private let userCD: UserServicesCoredata
    private let statCD: StatisticsServicesCoredata
    private let challengeCD: ChallengeServicesCoredata
    private let accessLogCD: AccessLogServicesCoredata
    
    private let userFS = UserServicesFirestore()
    private let statFS = StatisticsServicesFirestore()
    private let challengeFS = ChallengeServicesFirestore()
    private let accessLogFS = AccessLogServicesFirestore()
    
    private var syncLocalWithServer: SyncLocalWithServer
    private var syncServerWithLocal: SyncServerWithLocal
    private let maxSyncAttemps = 3
    
    // for component
    private var userId: String
    private var loginDate: Date
    private var userTerm: Int
    private var userData: UserInfoDTO
    
    /// `LoginLoadingService` 클래스의 인스턴스를 초기화합니다.
    ///
    /// 이 초기화 과정에서는 다음과 같은 작업이 수행됩니다:
    /// - 현재 날짜와 시간을 기록합니다.
    /// - 사용자 ID를 "Unknown"으로 초기화합니다.
    /// - 사용자 데이터와 통계 데이터를 각각 `UserInfoDTO`와 `StatLoginDTO`의 기본 인스턴스로 초기화합니다.
    ///
    /// 이 과정은 앱 내에서 로그인 과정을 시작하기 위한 기본 설정을 제공합니다.
    init(){
        self.loginDate = Date()
        self.userId = "Unknown"
        self.userData = UserInfoDTO()
        self.userTerm = 0
        
        self.syncLocalWithServer = SyncLocalWithServer(with: userId)
        self.syncServerWithLocal = SyncServerWithLocal(with: userId)
        self.userCD = UserServicesCoredata(coredataController: self.controller)
        self.statCD = StatisticsServicesCoredata(coredataController: self.controller)
        self.challengeCD = ChallengeServicesCoredata(coredataController: self.controller)
        self.accessLogCD = AccessLogServicesCoredata(coredataController: self.controller)
    }
    
    /// 사용자 로그인 프로세스를 실행합니다. 이 과정에서 로컬 데이터 검사, 사용자 필터링, (일간/주간)업데이트 진행여부 및 데이터 검증을 포함합니다.
    /// - Parameter dto: `AuthSocialLoginResDTO` 소셜 로그인 응답 데이터를 담고 있습니다.
    /// - Returns: 로그인 과정을 거친 후의 사용자 정보를 담은 `UserInfoDTO` 를 비동기적으로 반환합니다.
    /// - Throws: `LoginLoadingServiceError`의 경우들을 포함한 여러 에러를 던질 수 있습니다.
    func executor(with dto: AuthSocialLoginResDTO) async throws -> UserInfoDTO {
        
        self.loginDate = Date()
        self.userId = try util.getIdentifier(from: dto)
        print("init login process")
        
        if !checkLocalData() {
            print("init sync process")
            try await syncWithServer()
        }
        
        // Filitering 're-login' & 'first-login'
        if try userFiliter() {
            return UserInfoDTO(with: try userCD.getObject(with: userId))
        }
        
        self.userTerm = try statCD.getObject(with: userId).term
        try await updateBasedOnSorter(with: UpdateSorter())
        return UserInfoDTO(with: try userCD.getObject(with: userId))
    }
}

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


// MARK: - Filiter
extension LoginLoadingService{
    
    /// 이전 로그인 시간과 현재 시간을 비교하여 사용자를 필터링합니다. 사용자는 당일 첫 로그인 사용자와 재로그인 사용자로 나뉩니다.
    /// - Returns: 재로그인 사용자는  true, 당일 첫 로그인 사용자는 false를 반환합니다.
    /// - Throws: `LoginLoadingServiceError.EmptyAccessLog` 접속로그가 비어 있을 경우 발생합니다.
    private func userFiliter() throws -> Bool {
        
        let log = try accessLogCD.getObject(with: userId)
        return util.compareTime(currentTime: loginDate, lastTime: log.accessRecord)
    }
    
    /// 로컬에 필요한 모든 데이터가 존재하는지 확인합니다.
    /// - Returns: 모든 데이터(사용자, 통계정보, 접속 로그, 도전과제 로그)가 존재하면 true, 그렇지 않으면 false를 반환합니다.
    private func checkLocalData() -> Bool {
        let dataTypes: [CheckCase] = [.user, .stat, .accessLog, .challenge]
        return dataTypes.allSatisfy { doesDataExistInLocal(with: userId, for: $0) }
    }
    
    /// 지정된 유형의 로컬 데이터가 존재하는지 확인합니다.
    /// - Parameters:
    ///   - userId: 사용자 ID입니다.
    ///   - type: 검사할 데이터 유형을 나타내는 `CheckCase` 열거형입니다.
    /// - Returns: 지정된 데이터 유형이 존재하면 true, 그렇지 않으면 false를 반환합니다.
    private func doesDataExistInLocal(with userId: String, for type: CheckCase) -> Bool {
        print("init local data check")
        switch type {
        case .user:
            print("init local user check")
            return (try? userCD.getObject(with: userId)) != nil
        case .stat:
            print("init local stat check")
            return (try? statCD.getObject(with: userId)) != nil
        case .accessLog:
            print("init local log check")
            return (try? accessLogCD.getObjects(with: userId)).map { !$0.isEmpty } ?? false
        case .challenge:
            print("init local challenge check")
            return (try? challengeCD.getObjects(with: userId)).map { !$0.isEmpty } ?? false
        }
    }

    // Test: Erase All Local Data
    private func resetLocalData() throws {
        try userCD.deleteObject(with: userId)
        try statCD.deleteObject(with: userId)
        try challengeCD.deleteObject(with: userId)
        try accessLogCD.deleteObject(with: userId)
    }
}

// MARK: - Synchronize
extension LoginLoadingService {
    
    /// 로컬 데이터를 서버에 동기화하는 프로세스를 실행합니다.
    /// - Parameters:
    ///   - attemptCount: 현재까지 시도된 동기화 횟수입니다.
    ///   - loginDate: 로그인 시도 날짜입니다.
    /// - Throws: `LoginLoadingServiceError.TooManyLocalSyncAttempt` 동기화 시도가 최대 허용 횟수를 초과할 경우 발생합니다.
    private func syncWithServer(attemptCount: Int = 0) async throws {
        do {
            try await syncLocalWithServer.syncExecutor(with: userId)
        } catch {
            if attemptCount >= maxSyncAttemps {
                throw LoginLoadingError.syncLocalWithServerFailure(serviceName: .login)
            }
            try await syncWithServer(attemptCount: attemptCount + 1)
        }
        if !checkLocalData() {
            try await syncWithServer(attemptCount: 0)
        }
    }
}


// MARK: - Update
extension LoginLoadingService {
    
    private func UpdateSorter() -> UpdateType {
        if userTerm % 7 == 0 {
            return .weekly
        } else if userTerm % 90 == 0{
            return .quarterly
        } else {
            return .daily
        }
    }
    
    private func updateBasedOnSorter(with type: UpdateType) async throws {
        switch type {
        case .daily:
            try dailyUpdateProcess(with: loginDate)
        case .weekly:
            try dailyUpdateProcess(with: loginDate)
            try await weeklyUpdateProcess(at: loginDate)
        case .quarterly:
            try dailyUpdateProcess(with: loginDate)
            try quarterlyUpdateProcess(with: loginDate)
        }
    }
    
    /// 일일 업데이트를 진행합니다. 통계정보의 서비스 기간을 업데이트하고 접속로그에 로그인 시간을 기록합니다.
    /// - Parameter loginDate: 로그인 시도 날짜입니다.
    /// - Throws: 업데이트 실패 시 예외를 던집니다.
    private func dailyUpdateProcess(with loginDate: Date) throws {
        
        try updateServiceTerm()
        try updateLoginAt(with: loginDate)
    }
    
    /// 통계정보의 서비스 기간을 업데이트합니다.
    /// - Throws: 서비스 기간 업데이트 실패 시 예외를 던집니다.
    private func updateServiceTerm() throws {
        
        let newTerm = userTerm + 1
        let updated = StatUpdateDTO(userId: userId, newTerm: newTerm)
        try statCD.updateObject(with: updated)
    }
    
    /// 사용자정보의 최근 로그인 시간을 업데이트합니다.
    /// - Parameter loginDate: 새로운 로그인 시간입니다.
    /// - Throws: 로그인 시간 업데이트 실패 시 예외를 던집니다.
    private func updateLoginAt(with loginDate: Date) throws {
        
        let loginRecord = AccessLog(userId: userId, accessDate: loginDate)
        try accessLogCD.setObject(with: loginRecord)
    }
    
    private func weeklyUpdateProcess(attempCount: Int = 0, at syncDate: Date) async throws {
        do {
            try await syncServerWithLocal.syncExecutor(with: userId, and: syncDate)
        } catch {
            if attempCount >= maxSyncAttemps{
                throw LoginLoadingError.syncServerWithLocalFailure(serviceName: .login)
            }
            try await weeklyUpdateProcess(attempCount: attempCount + 1, at: syncDate)
        }
    }
    
    private func quarterlyUpdateProcess(with syncDate: Date, attempCount: Int = 0) throws {
        
        let user = try userCD.getObject(with: userId)
        let updated = UserUpdateDTO(userId: userId, newLogHead: user.accessLogHead + 1)
        try userCD.updateObject(with: updated)
    }
}

// MARK: - Enum
enum UpdateType {
    case daily
    case weekly
    case quarterly
}

enum CheckCase{
    case user
    case stat
    case accessLog
    case challenge
}
