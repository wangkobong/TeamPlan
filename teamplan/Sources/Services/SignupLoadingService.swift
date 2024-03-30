//
//  SignupLoadingService.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/10/20.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation

final class SignupLoadingService{
    
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
    
    private let logHead: Int
    private let userId: String
    private let signupDate: Date
    
    private let newProfile: UserObject
    private let newStat: StatisticsObject
    private let newLog: AccessLog
    
    private var rollbackStack: [() async throws -> Void ] = []
    
    
    /// `SignupLoadingService` 클래스의 인스턴스를 초기화합니다.
    ///
    /// 이 초기화 과정에서는 다음과 같은 작업이 수행됩니다:
    /// - 입력받은 `newUser` 객체에서 제공된 사용자 ID를 기반으로 `userId` 속성을 설정합니다.
    /// - 현재 날짜와 시간을 `signupDate`로 설정하여, 가입 시점을 기록합니다.
    /// - `UserObject`와 `StatisticsObject`를 생성하여, 새 사용자의 프로필 및 통계 데이터를 초기화합니다.
    /// - 신규 `AccessLog`와 `ChallengeLog`생성을 위해  'LogManager' 를 초기화합니다.
    ///
    /// 이 과정은 사용자가 앱에 가입할 때 필요한 기능들의 기본 설정을 제공합니다.
    init(newUser: UserSignupDTO){
        self.userCD = UserServicesCoredata(coredataController: self.controller)
        self.statCD = StatisticsServicesCoredata(coredataController: self.controller)
        self.challengeCD = ChallengeServicesCoredata(coredataController: self.controller)
        self.accessLogCD = AccessLogServicesCoredata(coredataController: self.controller)
        
        self.logHead = newUser.logHead
        self.userId = newUser.userId
        self.signupDate = Date()
        
        self.newProfile = UserObject(with: newUser, and: self.signupDate)
        self.newStat = StatisticsObject(with: newUser.userId, and: self.signupDate)
        self.newLog = AccessLog(with: newUser.userId, and: self.signupDate)
    }
    
    /// 신규 사용자 가입과정의 메인 실행 함수입니다.
    /// - Returns: 가입이 완료된 사용자 정보를 담고 있는 `UserInfoDTO` 객체를 반환합니다.
    /// - Throws: 데이터 저장 과정에서 오류가 발생하면 `SignupLoadingError.UnexpectedSignupError`를 던지며 롤백과정을 수행합니다.
    /// - 이 함수는 가입 과정을 여러 단계(로컬 저장, 서버 저장)별로 순차적으로 진행합니다.
    /// - 모든 단계가 성공적으로 완료되면 사용자 정보 DTO를 반환합니다. 실패 시 모든 변경 사항을 롤백합니다.
    func executor() async throws -> UserInfoDTO {
        
        let localResult: Bool
        let serverResult: Bool
    
        localResult = try localExecutor()
        serverResult = try await serverExecutor()
        
        // Apply Execute
        switch (localResult, serverResult) {
            
        case (true, true):
            return UserInfoDTO(with: newProfile)
            
        default:
            try await rollbackAll()
            throw SignupLoadingError.signupFailure(serviceName: .signup)
        }
    }
    
    /// 로컬 디바이스에 신규 사용자 데이터를 저장하는 핵심 기능 함수입니다.
    /// - Returns: 데이터 저장 성공 여부를 나타내는 Bool 값입니다.
    /// - Throws: 저장 과정에서 오류가 발생하면 예외를 던집니다.
    /// - 이 함수는 사용자 프로필, 통계정보, 접속 로그, 도전과제 로그를 로컬(Coredata)에 저장합니다.
    /// - 실패 시, 각 단계를 롤백할 수 있는 함수를 롤백 스택에 추가하며, 성공 시 스택을 비웁니다.
    private func localExecutor() throws -> Bool {
        do {
            try setNewUserProfileAtLocal()
            rollbackStack.append(rollbackSetNewUserProfileAtLocal)
            
            try setNewStatAtLocal()
            rollbackStack.append(rollbackSetNewStatAtLocal)
            
            try setNewAccessLogAtLocal()
            rollbackStack.append(rollbackSetNewAccessLogAtLocal)
            
            rollbackStack.removeAll()
            return true
            
        } catch {
            return false
        }
    }
    
    /// 서버DB에 신규 사용자 데이터를 저장하는 핵심 기능 함수입니다.
    /// - Returns: 데이터 저장 성공 여부를 나타내는 Bool 값입니다.
    /// - Throws: 저장 과정에서 오류가 발생하면 예외를 던집니다.
    /// - 이 함수는 사용자 프로필, 통계정보, 접속 로그, 도전과제 로그를 서버DB(Firestore)에 저장합니다.
    /// - 서버에 저장된 도전과제 정보를 조회하고, 로컬에 저장합니다.
    /// - 실패 시, 각 단계를 롤백할 수 있는 함수를 롤백 스택에 추가하며, 성공 시 스택을 비웁니다.
    private func serverExecutor() async throws -> Bool {
        do {
            try await setNewUserProfileAtServer()
            rollbackStack.append(rollbackSetNewUserProfileAtServer)
            
            try await setNewStatAtServer()
            rollbackStack.append(rollbackSetNewStatAtServer)
            
            try await setNewAccessLogAtServer()
            rollbackStack.append(rollbackSetNewAccessLogAtServer)
        
            try await setNewChallengeAtLocal()
            rollbackStack.append(rollbackSetNewChallengeAtLocal)
            
            try await setNewChallengeStatusAtServer()
            rollbackStack.append(rollbackSetNewChallengeStatusAtServer)
            
            rollbackStack.removeAll()
            return true
            
        } catch {
            return false
        }
    }
    
    /// 저장 과정 중 발생한 모든 변경 사항을 롤백하는 함수입니다.
    /// - Throws: 롤백 과정에서 오류가 발생하면 예외를 던집니다.
    /// - 이 함수는 롤백 스택에 추가된 작업을 역순으로 실행하여 누적된 변경 사항을 되돌립니다.
    private func rollbackAll() async throws {
        for rollback in rollbackStack.reversed() {
            try await rollback()
        }
        rollbackStack.removeAll()
    }
}


// MARK: - User
extension SignupLoadingService{
    
    // : Coredata
    private func setNewUserProfileAtLocal() throws {
        try userCD.setObject(with: newProfile)
    }
    private func rollbackSetNewUserProfileAtLocal() throws {
        try userCD.deleteObject(with: userId)
    }
    
    // : Firestore
    private func setNewUserProfileAtServer() async throws {
        try await userFS.setDocs(with: newProfile)
    }
    private func rollbackSetNewUserProfileAtServer() async throws {
        try await userFS.deleteDocs(with: userId)
    }
}


// MARK: - Statisticcs
extension SignupLoadingService{
    
    // : Coredata
    private func setNewStatAtLocal() throws {
        try statCD.setObject(with: newStat)
    }
    private func rollbackSetNewStatAtLocal() throws {
        try statCD.deleteObject(with: userId)
    }
    
    // : Firestore
    private func setNewStatAtServer() async throws {
        try await statFS.setDocs(with: newStat)
    }
    private func rollbackSetNewStatAtServer() async throws {
        try await statFS.deleteDocs(with: userId)
    }
}


// MARK: - AccessLog
extension SignupLoadingService{
    
    // : CoreData
    private func setNewAccessLogAtLocal() throws {
        try accessLogCD.setObject(with: newLog)
    }
    private func rollbackSetNewAccessLogAtLocal() throws {
        try accessLogCD.deleteObject(with: userId)
    }
    
    // : Firestore
    private func setNewAccessLogAtServer() async throws {
        try await accessLogFS.setDocs(with: userId, and: logHead, and: [newLog])
    }
    private func rollbackSetNewAccessLogAtServer() async throws {
        try await accessLogFS.deleteDocs(with: userId)
    }
}

// MARK: - Challenge
extension SignupLoadingService{

    // : Coredata
    private func setNewChallengeAtLocal() async throws {
        
        let challengeInfo = try await challengeFS.getInfoDocsList()
        for challenge in challengeInfo {
            let object = prepareNewChallengeStatus(with: challenge)
            try challengeCD.setObject(with: object)
        }
    }
    private func rollbackSetNewChallengeAtLocal() throws {
        try challengeCD.deleteObject(with: userId)
    }
    
    // : Firestore
    private func setNewChallengeStatusAtServer() async throws {
        let challenges = try challengeCD.getObjects(with: userId)
        try await challengeFS.setDocs(with: challenges, and: userId)
    }
    private func rollbackSetNewChallengeStatusAtServer() async throws {
        try await challengeFS.deleteDocs(with: userId)
    }
}

//MARK: - New User Info
extension UserObject {
    init(with dto: UserSignupDTO, and signupDate: Date) {
        self.userId = dto.userId
        self.email = dto.email
        self.name = dto.nickName
        self.socialType = dto.provider
        self.status = .active
        self.accessLogHead = dto.logHead
        self.createdAt = signupDate
        self.changedAt = signupDate
        self.syncedAt = signupDate
    }
}

extension StatisticsObject {
    init(with userId: String, and signupDate: Date) {
        self.userId = userId
        self.term = 1
        self.drop = 0
        self.totalRegistedProjects = 0
        self.totalFinishedProjects = 0
        self.totalFailedProjects = 0
        self.totalAlertedProjects = 0
        self.totalExtendedProjects = 0
        self.totalRegistedTodos = 0
        self.totalFinishedTodos = 0
        self.challengeStepStatus = [
            ChallengeType.serviceTerm.rawValue : 1,
            ChallengeType.totalTodo.rawValue : 1,
            ChallengeType.projectAlert.rawValue : 1,
            ChallengeType.projectFinish.rawValue : 1,
            ChallengeType.waterDrop.rawValue : 1
        ]
        self.mychallenges = []
        self.syncedAt = signupDate
    }
}

extension AccessLog {
    init(with userId: String, and signupDate: Date) {
        self.userId = userId
        self.accessRecord = signupDate
    }
}

extension SignupLoadingService {
    private func prepareNewChallengeStatus(with dto: ChallengeInfoDTO) -> ChallengeObject{
        return ChallengeObject(
            challengeId: dto.challengeId,
            userId: userId,
            title: dto.title,
            desc: dto.desc,
            goal: dto.goal,
            type: dto.type,
            reward: dto.reward,
            step: dto.step,
            version: dto.version,
            status: false,            // false(inComplete), true(complete)
            lock: dto.step != 1,      // false(unlock), true(locked)
            progress: 0,
            selectStatus: false,      // false(notSelected), true(selected)
            selectedAt: signupDate,
            unselectedAt: signupDate,
            finishedAt: signupDate
        )
    }
}
