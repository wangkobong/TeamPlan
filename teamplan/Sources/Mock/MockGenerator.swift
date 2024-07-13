//
//  MockGenerator.swift
//  teamplan
//
//  Created by 크로스벨 on 6/27/24.
//  Copyright © 2024 team1os. All rights reserved.
//
/*
import Foundation

final class MockGenerator {
    
    private var userId: String
    private let userCD = UserServicesCoredata()
    private let statCD = StatisticsServicesCoredata()
    private let projectCD = ProjectLocalRepo()
    private let challengeCD = ChallengeServicesCoredata()
    private let accessLogCD = AccessLogServicesCoredata()
    private let projectLogCD = ProjectExtendLogServicesCoredata()
    
    var localUser: UserObject
    var localStat : StatisticsObject
    var localChallenges : [ChallengeObject]
    
    // mock Properties
    var mockUser: UserObject
    var mockStat : StatisticsObject
    var mockChallenges : [ChallengeObject]
    var mockAccessLogs : [AccessLog]
    var mockProjectId : Int
    var mockProjects : [ProjectObject]
    var mockProjectLog : [Int : [ProjectExtendLog]]
    
    init(userId: String) {
        self.userId = userId
        self.localUser = UserObject()
        self.localStat = StatisticsObject()
        self.localChallenges = []
        
        self.mockUser = UserObject()
        self.mockStat = StatisticsObject()
        self.mockChallenges = []
        self.mockAccessLogs = []
        self.mockProjectId = 0
        self.mockProjects = []
        self.mockProjectLog = [:]
    }
    
    //MARK: Executor
    
    func createMockExecutor() async -> Bool {
        if await prepareDataExecutor() {
            if await generateMockExecutor() {
                return await setDataExecutor()
            } else {
                return false
            }
        } else {
            return false
        }
    }
    
    //MARK: Local Fetch
    
    private func prepareDataExecutor() async -> Bool {
        async let isLocalUserFetch = fetchUserFromLocal()
        async let isLocalStatFetch = fetchStatFromLocal()
        async let isLocalAccessLogFetch = fetchAccessLogFromLocal()
        async let isLocalChallengeFetch = fetchChallengeFromLocal()
        
        let results = await [isLocalUserFetch, isLocalStatFetch, isLocalAccessLogFetch, isLocalChallengeFetch]
        if results.allSatisfy({$0}){
            print("[mockGen] Successfully prepare data")
            return true
        } else {
            print("[mockGen] Failed to prepare data")
            return false
        }
    }
    
    // User
    // properties only can change at, 'name, changedAt'
    private func fetchUserFromLocal() async -> Bool {
        do {
            self.localUser = try userCD.getObject(with: userId)
            return true
        } catch {
            print("[mockGen] Failed to fetch UserData from storage")
            return false
        }
    }
    
    // Stat
    // properties can change except, 'userId, syncedAt'
    private func fetchStatFromLocal() async -> Bool {
        do {
            self.localStat = try statCD.getObject(with: userId)
            return true
        } catch {
            print("[mockGen] Failed to fetch StatData from storage")
            return false
        }
    }
    
    // AccessLog
    // properties can change only at 'accessRecord'
    // 1 object mean, 1 log
    // LogList mean [AccessLog]
    private func fetchAccessLogFromLocal() async -> Bool {
        do {
            self.mockAccessLogs = try accessLogCD.getFullObjects(with: userId)
            return true
        } catch {
            print("[mockGen] Failed to fetch AccessLog from storage")
            return false
        }
    }
    
    // Challenge
    // properties can change only at 'status, lock, selectStatus, selectedAt, unselectedAt, finishedAt'
    private func fetchChallengeFromLocal() async -> Bool {
        do {
            self.localChallenges = try challengeCD.getObjects(with: userId)
            return true
        } catch {
            print("[mockGen] Failed to fetch Challenges from storage")
            return false
        }
    }
    
    // Project
    // need to generate mock data
    
    // ProjectExtendLog
    // need to generate mock data
    // must relate with mock porject & mock Project Extend Count
}

//MARK: Generate Mock

extension MockGenerator {
    
    private func generateMockExecutor() async -> Bool {
        let today = Date()
        
        async let isMockUserGenerate = generateUser()
        async let isMockStatGenerate = generateStat()
        async let isMockAccessLogGenerate = generateAccessLog(with: today)
        async let isMockChallengeGenerate = generateChallenges(with: today)
        async let isMockProjectGenerate = generateProject()
        async let isMockProjectLogGenerate = generateProjectLog()
        
        let results = await [isMockUserGenerate, isMockStatGenerate, isMockAccessLogGenerate, isMockChallengeGenerate, isMockProjectGenerate, isMockProjectLogGenerate]
        
        if results.allSatisfy({$0}) {
            print("[mockGen] Successfully create mock data")
            return true
        } else {
            print("[mockGen] Failed to create mock data")
            return false
        }
    }
    
    private func generateUser() async -> Bool {
        self.mockUser = UserObject(
            userId: userId,
            email: localUser.email,
            name: "MockData Applied",
            socialType: localUser.socialType,
            status: localUser.status,
            accessLogHead: localUser.accessLogHead,
            createdAt: localUser.createdAt,
            changedAt: Date(),
            syncedAt: localUser.syncedAt
        )
        return true
    }
    
    private func generateStat() async -> Bool {
        self.mockStat = StatisticsObject(
            userId: userId,
            term: 100,
            drop: 100,
            totalRegistedProjects: 5,
            totalFinishedProjects: 100,
            totalFailedProjects: 100,
            totalAlertedProjects: 100,
            totalExtendedProjects: 3,
            totalRegistedTodos: 100,
            totalFinishedTodos: 100,
            challengeStepStatus: localStat.challengeStepStatus,
            mychallenges: localStat.mychallenges,
            syncedAt: localStat.syncedAt
        )
        return true
    }
    
    private func generateAccessLog(with date: Date) async -> Bool {
        let calendar = Calendar.current
        
        for i in 0..<10 {
            // Creating a date in the past for each log
            if let accessDate = calendar.date(byAdding: .day, value: -i, to: date) {
                let log = AccessLog(userId: userId, accessDate: accessDate)
                self.mockAccessLogs.append(log)
            }
        }
        return true
    }
    
    private func generateChallenges(with date: Date) async -> Bool {
        for challenge in localChallenges {
            self.mockChallenges.append(
                ChallengeObject(
                    challengeId: challenge.challengeId,
                    userId: userId,
                    title: challenge.title,
                    desc: challenge.desc,
                    goal: challenge.goal,
                    type: challenge.type,
                    reward: challenge.reward,
                    step: challenge.step,
                    version: challenge.version,
                    status: challenge.status,
                    lock: challenge.lock,
                    progress: 100,
                    selectStatus: challenge.selectStatus,
                    selectedAt: date,
                    unselectedAt: date,
                    finishedAt: date
                )
            )
        }
        return true
    }
    
    private func generateProject() async -> Bool {
        let calendar = Calendar.current
        let date = Date()
        let titles = ["Project Alpha", "Project Beta", "Project Charlie", "Project Delta", "Project Echo"]
        
        for i in 1...5 {
            if let registedAt = calendar.date(byAdding: .day, value: +i, to: date) {
                let projectId = i
                let project = ProjectObject(
                    projectId: projectId,
                    userId: userId,
                    title: titles[i - 1],
                    status: .ongoing,
                    todos: [],
                    totalRegistedTodo: 0,
                    dailyRegistedTodo: 0,
                    finishedTodo: 0,
                    alerted: 1,
                    extendedCount: i <= 3 ? 5 : 0,
                    registedAt: registedAt,
                    startedAt: registedAt,
                    deadline: registedAt,
                    finishedAt: registedAt,
                    syncedAt: registedAt
                )
                self.mockProjects.append(project)
            }
        }
        return true
    }
    
    private func generateProjectLog() async -> Bool {
        for projectId in 1...3 {
            var extendLogs : [ProjectExtendLog] = []
            for extendCount in 1...5 {
                extendLogs.append(ProjectExtendLog(
                    projectId: projectId,
                    extendCount: extendCount,
                    userId: userId,
                    usedDrop: extendCount * 2,
                    storedDrop: extendCount * 3,
                    extendPeriod: extendCount * 7,
                    extendAt: Calendar.current.date(byAdding: .day, value: extendCount, to: Date())!,
                    newDeadline: Calendar.current.date(byAdding: .day, value: 20 + extendCount, to: Date())!,
                    totalRegistedTodo: 0,
                    totalFinshedTodo: 0)
                )
            }
            self.mockProjectLog[projectId] = extendLogs
        }
        return true
    }
}

//MARK: Set MockData at Local

extension MockGenerator {

    private func setDataExecutor() async -> Bool {
        async let isUserSet = setMockUserAtLocal()
        async let isStatSet = setMockStatAtLocal()
        async let isChallengesSet = setMockChallengesAtLocal()
        async let isProjectsSet = setMockProjectsAtLocal()
        async let isAccessLogsSet = setMockAccessLogsAtLocal()
        async let isProjectLogsSet = setMockProjectLogsAtLocal()
        
        let results = await [isUserSet, isStatSet, isChallengesSet, isProjectsSet, isAccessLogsSet, isProjectLogsSet]
        
        if results.allSatisfy({ $0 }) {
            return await LocalStorageManager.shared.saveContext()
        } else {
            print("[MockGen] Failed to set mock data at local")
            return false
        }
    }
    
    private func setMockUserAtLocal() async -> Bool {
        userCD.setObject(with: self.mockUser)
        return true
    }
    
    private func setMockStatAtLocal() async -> Bool {
        do {
            try statCD.setObject(with: self.mockStat)
            return true
        } catch {
            print("[MockGen] failed to set stat mock data")
            return false
        }
    }
    
    private func setMockChallengesAtLocal() async -> Bool{
        for challenge in self.mockChallenges {
            challengeCD.setObject(with: challenge)
        }
        return true
    }
    
    private func setMockProjectsAtLocal() async -> Bool {
        for project in mockProjects {
            projectCD.setObject(with: project)
        }
        return true
    }
    
    private func setMockAccessLogsAtLocal() async -> Bool {
        for mockAccessLog in mockAccessLogs {
            accessLogCD.setObject(with: mockAccessLog)
        }
        return true
    }
    
    private func setMockProjectLogsAtLocal() async -> Bool {
        for logs in mockProjectLog.values {
            print("[MockGen] Mock ProjectLogs : \(logs.count)")
            for log in logs {
                projectLogCD.setObject(with: log)
            }
        }
        return true
    }
}

//MARK: Delete MockData

extension MockGenerator {
    
    // Executor for Deleting Mock Data
    func deleteMockDataExecutor() async -> Bool {
        do {
            try await deleteMockProjects()
            try await deleteMockProjectLogs()
            
            if await LocalStorageManager.shared.saveContext() {
                print("[MockGen] Successfully deleted mock data from local")
                return true
            } else {
                print("[MockGen] Failed to save context after deleting mock data")
                return false
            }
        } catch {
            print("[MockGen] Failed to delete mock data: \(error)")
            return false
        }
    }
    
    private func deleteMockProjects() async throws {
        for project in mockProjects {
            try projectCD.deleteObject(with: userId, and: project.projectId)
        }
    }
    
    private func deleteMockProjectLogs() async throws {
        for projectId in mockProjectLog.keys {
            try await projectLogCD.deleteObject(with: projectId, and: userId)
        }
    }
}
*/
