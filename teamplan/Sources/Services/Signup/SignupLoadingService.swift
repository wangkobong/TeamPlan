//
//  SignupLoadingService.swift
//  teamplan
//
//  Created by 주찬혁 on 2023/10/20.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

final class SignupLoadingService {
    
    // shared
    var userData: UserInfoDTO
    var isDataPrepared: Bool = false            // false : fetch failed, need to re-signup
    var isCompletelyDeleted: Bool = false       // false : rollback failed, need to reset
    var isReadyToReSignup = false               // false : reset failed, need to inform user
    
    // private
    private let mock: MockGenerator
    
    private let userCD = UserServicesCoredata()
    private let statCD = StatisticsServicesCoredata()
    private let challengeCD = ChallengeServicesCoredata()
    private let accessLogCD = AccessLogServicesCoredata()
    private let coreValueCD = CoreValueServicesCoredata()
    
    private let userFS = UserServicesFirestore()
    private let statFS = StatisticsServicesFirestore()
    private let challengeFS = ChallengeServicesFirestore()
    private let accessLogFS = AccessLogServicesFirestore()
    private let coreValueFS = CoreValueServicesFirestore()
    
    private let logHead: Int
    private let userId: String
    private let signupDate: Date
    
    private let newProfile: UserObject
    private let newStat: StatisticsObject
    private let newLog: AccessLog
    
    private var coreValue = CoreValueObject()
    private var challengeList = [ChallengeObject]()
    private var challengeIdSet = Set<Int>()
    private var rollbackStack: [() async -> Void ] = []
    
    private let viewManager: TopViewManager
    private let networkManager: NetworkManager
    private let localStorageManager: LocalStorageManager
    
    init(newUser: UserSignupDTO){
        self.logHead = newUser.logHead
        self.userId = newUser.userId
        self.signupDate = Date()
        self.userData = UserInfoDTO()
        
        self.newProfile = UserObject(with: newUser, and: self.signupDate)
        self.newStat = StatisticsObject(with: newUser.userId, and: self.signupDate)
        self.newLog = AccessLog(with: newUser.userId, and: self.signupDate)
        
        self.mock = MockGenerator(userId: newUser.userId)
        self.viewManager = TopViewManager.shared
        self.localStorageManager = LocalStorageManager.shared
        self.networkManager = NetworkManager.shared
    }
}

// MARK: - Main Executor

enum SignupLoadingServiceAction: String {
    case fetch = "FetchExecutor"
    case local = "LocalExecutor"
    case server = "ServerExecutor"
}

extension SignupLoadingService {

    // controller
    func executor() async {
        
//        if await !networkManager.checkNetworkConnection() {
//            await failedProcess(.network)
//            return
//        }
        
        if await !serviceExecutor(.fetch) {
            await failedProcess(.fetch)
            return
        }
        
        if await !serviceExecutor(.local) {
            await failedProcess(.localSet)
            return
        }
        
        if await !serviceExecutor(.server) {
            await failedProcess(.serverSet)
            return
        }
        
        /* Insert Mock Data
        if await !mock.createMockExecutor() {
            print("[SignupLoading] Failed to create mockData")
            return
        }
         */
        
        self.userData = UserInfoDTO(with: newProfile)
    }
    
    private func actionExecutor(_ action: SignupLoadingServiceAction) async -> Bool {
        switch action {
        case .fetch:
            return await fetchExecutor()
        case .local:
            return await localExecutor()
        case .server:
            return await serverExecutor()
        }
    }
    
    private func serviceExecutor(_ action: SignupLoadingServiceAction) async -> Bool {
        let max = 3
        var retryCount = 1
        var isProcessComplete = false
        
        while retryCount <= max && !isProcessComplete {
            isProcessComplete = await actionExecutor(action)
            
            if !isProcessComplete {
                print("[SingupLoading] Retrying '\(action.rawValue)' action... \(retryCount)/\(max)")
                retryCount += 1
            }
        }
        if !isProcessComplete {
            print("[SingupLoading] Failed to execute '\(action.rawValue)' action after \(max) retries")
            return false
        }
        print("[SingupLoading] Successfully executed '\(action.rawValue)' action in \(retryCount) tries")
        return true
    }
    
    // fetch
    private func fetchExecutor() async -> Bool {
        async let isCoreValueFetch = fetchCoreValueFromServer()
        async let isChallengeFetch = fetchChallengFromServer()
        
        let results = await [isCoreValueFetch, isChallengeFetch]
        return results.allSatisfy{ $0 }
    }
    
    // set at local
    private func localExecutor() async -> Bool {
        async let isNewUserDataSet = setNewUserProfileAtLocal()
        async let isNewStatDataSet = setNewStatAtLocal()
        async let isAccessLogSet = setNewAccessLogAtLocal()
        async let isChallengeSet = setNewChallengeAtLocal()
        async let isCoreValueSet = setNewCoreValueAtLocal()
        
        let results = await [isNewUserDataSet, isNewStatDataSet, isAccessLogSet, isChallengeSet, isCoreValueSet]
        return await localSetProcess(results: results)
    }
    
    private func localSetProcess(results: [Bool]) async -> Bool {
        if !results.allSatisfy({$0}) {
            return false
        }
        if await localStorageManager.saveContext() {
            return true
        } else {
            await localStorageManager.resetContext()
            return false
        }
    }
    
    // set at server
    private func serverExecutor() async -> Bool {
        let batch = Firestore.firestore().batch()
        
        async let isNewUserDataSet = setNewUserProfileAtServer(with: batch)
        async let isNewStatDataSet = setNewStatAtServer(with: batch)
        async let isNewAccessLogSet = setNewAccessLogAtServer(with: batch)
        async let isChallengeSet = setNewChallengeStatusAtServer(with: batch)
        
        let results = await [isNewUserDataSet, isNewStatDataSet, isNewAccessLogSet, isChallengeSet]
        return await serverSetProcess(results: results, batch: batch)
    }
    
    private func serverSetProcess(results: [Bool], batch: WriteBatch) async -> Bool {
        // set batch failed
        if !results.allSatisfy({$0}) {
            print("[SignupLoading] Failed to struct set newUserData batch")
            return false
        }
        if await commitBatch(with: batch) {
            print("[SignupLoading] Successfully Set newUserData batch at Server")
            return true
        } else {
            print("[SignupLoading] Failed to process newUserData batch at Server")
            return false
        }
    }
}

enum SignupFailedCase {
    case network
    case fetch
    case localSet
    case serverSet
}

extension SignupLoadingService {
    private func failedProcess(_ pos: SignupFailedCase) async {
        var title: String
        var message: String
        
        switch pos {
        case .network:
            print("[SignupLoading] Unstable Network Connection")
            title = "연결경고!"
            message = "인터넷 연결이 불안정합니다. 여녁ㄹ이 원활한 환경에서 회원가입을 재시도해주세요"
            
        case .fetch:
            print("[SignupLoading] Unable to fetch data from server")
            title = "오류확인!"
            message = "서버와의 연결이 불안정합니다. 회원가입을 재시도해 주세요"

        case .localSet:
            print("[SignupLoading] Unable to set data locally")
            title = "오류확인!"
            message = "서비스 동작중 오류가 발생하였습니다! 문제가 계속될 경우 재설치 해주세요"
            
        case .serverSet:
            print("[SignupLoading] Unable to set data on server")
            title = "오류확인!"
            message = "서버와의 연결이 불안정합니다. 회원가입을 재시도해 주세요"
            
            await localStorageManager.rebuildContext()
        }
        await removeUserAtAuth()
        await viewManager.redirectToLoginView(title: title, message: message)
    }
}

// MARK: - User
extension SignupLoadingService{
    
    // : Coredata
    private func setNewUserProfileAtLocal() async -> Bool {
        userCD.setObject(with: newProfile)
        print("[SingupLoading] Successfully set UserData at storage")
        return true
    }
    
    // : Firestore
    private func setNewUserProfileAtServer(with batch: WriteBatch) async -> Bool {
        await userFS.setDocs(with: newProfile, and: batch)
        print("[SingupLoading] Successfully set UserData at batch")
        return true
    }
}


// MARK: - Statisticcs
extension SignupLoadingService{
    
    // : Coredata
    private func setNewStatAtLocal() async -> Bool {
        do {
            try statCD.setObject(with: newStat)
            print("[SingupLoading] Successfully set StatData at storage")
            return true
        } catch {
            print("[SingupLoading] Failed to set StatData at storage")
            return false
        }
    }
    
    // : Firestore
    private func setNewStatAtServer(with batch: WriteBatch) async -> Bool {
        do {
            try await statFS.setDocs(with: newStat, and: batch)
            print("[SingupLoading] Successfully set StatData at batch")
            return true
        } catch {
            print("[SingupLoading] Failed to set StatData at batch")
            return false
        }
    }
}


// MARK: - AccessLog
extension SignupLoadingService{
    
    // : CoreData
    private func setNewAccessLogAtLocal() async -> Bool {
        accessLogCD.setObject(with: newLog)
        print("[SingupLoading] Successfully set AccessLog at storage")
        return true
    }
    
    // : Firestore
    private func setNewAccessLogAtServer(with batch: WriteBatch) async -> Bool {
        await accessLogFS.setDocs(with: userId, and: logHead, and: [newLog], and: batch)
        print("[SingupLoading] Successfully set AccessLog at batch")
        return true
    }
}

// MARK: - Challenge
extension SignupLoadingService{

    // : Coredata
    private func setNewChallengeAtLocal() async -> Bool {
        for challenge in challengeList {
            challengeCD.setObject(with: challenge)
        }
        print("[SingupLoading] Successfully set Challenge at storage")
        return true
    }
    
    // : Firestore
    private func fetchChallengFromServer() async -> Bool {
        do {
            let challengeInfo = try await challengeFS.getInfoDocsList()
            for challenge in challengeInfo where !challengeIdSet.contains(challenge.challengeId) {
                challengeIdSet.insert(challenge.challengeId)
                challengeList.append(prepareNewChallengeStatus(with: challenge))
            }
            print("[SingupLoading] Successfully fetch Challenge from server: \(challengeList.count)")
            return true
        } catch {
            print("[SingupLoading] Failed fetch Challenge from server")
            self.isDataPrepared = false
            return false
        }
    }
    private func setNewChallengeStatusAtServer(with batch: WriteBatch) async -> Bool {
        do {
            try await challengeFS.setDocs(with: challengeList, and: userId, and: batch)
            print("[SingupLoading] Successfully set Challenge at batch")
            return true
        } catch {
            print("[SingupLoading] Failed to set Challenge at server")
            return false
        }
    }
}

// MARK: - CoreValue
extension SignupLoadingService{
    
    private func fetchCoreValueFromServer() async -> Bool {
        do {
            self.coreValue = try await coreValueFS.getDocs(with: userId)
            print("[SingupLoading] Successfully fetch CoreValue from server")
            return true
        } catch {
            print("[SingupLoading] Failed fetch CoreValue from server")
            self.isDataPrepared = false
            return false
        }
    }
    
    private func setNewCoreValueAtLocal() async -> Bool {
        coreValueCD.setObject(with: coreValue)
        print("[SingupLoading] Successfully set CoreValue at storage")
        return true
    }
}


// MARK: - Firebase
extension SignupLoadingService{
    
    private func removeUserAtAuth() async {
        
        guard let user = Auth.auth().currentUser else {
            print("[SingupLoading] There is no user to remove at FirebaseAuth")
            return
        }
        do {
            try await user.delete()
            print("[SingupLoading] Successfully remove user at FirebaseAuth")
        } catch {
            print("[SingupLoading] Failed to remove user at FirebaseAuth")
            return
        }
    }
    
    private func commitBatch(with batch: WriteBatch) async -> Bool {
        do {
            try await batch.commit()
            return true
        } catch {
            print("[SingupLoading] Failed to set newUserData at Server: \(error.localizedDescription)")
            return false
        }
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
