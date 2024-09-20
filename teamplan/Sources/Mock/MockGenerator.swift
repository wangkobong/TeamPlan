//
//  MockGenerator.swift
//  teamplan
//
//  Created by 크로스벨 on 6/27/24.
//  Copyright © 2024 team1os. All rights reserved.
//

import CoreData
import Foundation

final class MockGenerator {
    
    private var localStat : StatisticsObject
    private var localAccessLog: [AccessLog]
    
    private let statCD: StatisticsServicesCoredata
    private let accessLogCD: AccessLogServicesCoredata
    private let projectCD: ProjectServicesCoredata
    private let storageManager: LocalStorageManager
    
    private let notifySC: NotificationService
    
    private var userId: String
    
    // mock Properties
    private var mockStat : StatUpdateDTO
    private var mockAccessLog: [AccessLog]
    private var mockProjectId : Int
    private var mockProjects : [ProjectObject]
    
    init(userId: String) {
        self.userId = userId
        self.localStat = StatisticsObject()
        self.localAccessLog = []
        
        self.mockStat = StatUpdateDTO(userId: userId)
        self.mockAccessLog = []
        self.mockProjectId = 0
        self.mockProjects = []
        
        self.statCD = StatisticsServicesCoredata()
        self.accessLogCD = AccessLogServicesCoredata()
        self.projectCD = ProjectServicesCoredata()
        self.storageManager = LocalStorageManager.shared
        
        self.notifySC = NotificationService(userId: userId)
    }
    
    //MARK: Executor
    
    func injectMockData() async -> Bool {
        
        guard prepareDataExecutor() else {
            print("[mockGen] Failed to get localData")
            return false
        }
        
        guard await generateMockExecutor() else {
            print("[mockGen] Failed to generate mockData")
            return false
        }
        
        guard setDataExecutor() else {
            print("[mockGen] Failed to apply mockData at storage")
            return false
        }
        
        guard await notifySC.firstLoginExecutor() else {
            print("[mockGen] Failed to prepare notifyData")
            return false
        }
        return true
    }
}

//MARK: Local Fetch

extension MockGenerator {
    
    private func prepareDataExecutor() -> Bool {
        let context = storageManager.context
        var results = [Bool]()
        
        context.performAndWait {
            results = [
                fetchStatData(with: context),
                fetchAccessLogData(context: context)
            ]
        }
        
        if results.allSatisfy({$0}){
            return true
        } else {
            print("[mockGen] Failed to prepare data")
            return false
        }
    }
    
    // Stat
    private func fetchStatData(with context: NSManagedObjectContext) -> Bool {
        do {
            guard try statCD.getObject(context: context, userId: userId) else {
                print("[NotifySC] Error detected while converting StatEntity to object")
                return false
            }
            self.localStat = statCD.object
            return true
        } catch {
            print(error.localizedDescription)
            return false
        }
    }
    
    // AccessLog
    private func fetchAccessLogData(context: NSManagedObjectContext) -> Bool {
        do {
            guard try accessLogCD.getFullObjects(context: context, userId: userId) else {
                print("[ServerSync] Failed to convert AccessLog")
                return false
            }
            self.localAccessLog = accessLogCD.objects
            return true
        } catch {
            print("[ServerSync] Failed to fetch AccessLog from storage")
            return false
        }
    }
}

//MARK: Generate Mock

extension MockGenerator {
    
    private func generateMockExecutor() async -> Bool {
        let today = Date()
        
        async let isMockStatGenerate = generateStat()
        async let isMockAccessLogGenerate = generateAccessLog(with: today)
        async let isMockProjectGenerate = generateProject()
        
        let results = await [isMockStatGenerate, isMockAccessLogGenerate, isMockProjectGenerate]
        
        if results.allSatisfy({$0}) {
            return true
        } else {
            print("[mockGen] Failed to create mock data")
            return false
        }
    }
    
    private func generateStat() async -> Bool {
        
        self.mockStat.newTerm = 100
        self.mockStat.newDrop = 100
        self.mockStat.newTotalRegistedProjects = localStat.totalRegistedProjects + 5
        self.mockStat.newTotalFinishedProjects = 100
        self.mockStat.newTotalFailedProjects = 100
        self.mockStat.newTotalAlertedProjects = 100
        self.mockStat.newTotalExtendedProjects = 50
        self.mockStat.newTotalRegistedTodos = 200
        self.mockStat.newTotalFinishedTodos = 400
        return true
    }
    
    private func generateAccessLog(with date: Date) async -> Bool {
        let calendar = Calendar.current
        
        for i in 0..<50 {
            if let accessDate = calendar.date(byAdding: .day, value: -i, to: date) {
                let log = AccessLog(userId: userId, accessDate: accessDate)
                mockAccessLog.append(log)
            }
        }
        
        for log in localAccessLog {
            mockAccessLog.append(log)
        }
        
        mockAccessLog.sort{ $0.accessRecord < $1.accessRecord }
        return true
    }
    
    private func generateProject() async -> Bool {
        let calendar = Calendar.current
        let date = Date()
        let titles = ["Project Alpha", "Project Beta", "Project Charlie", "Project Delta", "Project Echo"]
        
        for i in 1...5 {
            let projectId = i
            let registedAt = date
            let startedAt: Date
            let deadline: Date
            
            switch i {
            case 1:
                // Trigger halfway notification
                startedAt = calendar.date(byAdding: .day, value: -10, to: date)!
                deadline = calendar.date(byAdding: .day, value: 10, to: date)!
                
            case 2:
                // Trigger nearDeadline (3/4 of the total period)
                startedAt = calendar.date(byAdding: .day, value: -12, to: date)!
                deadline = calendar.date(byAdding: .day, value: 4, to: date)!
                
            case 3:
                // Trigger oneDayLeft notification
                startedAt = calendar.date(byAdding: .day, value: -14, to: date)!
                deadline = calendar.date(byAdding: .day, value: 1, to: date)!
                
            case 4:
                // Trigger theDay notification
                startedAt = calendar.date(byAdding: .day, value: -15, to: date)!
                deadline = calendar.date(byAdding: .day, value: 0, to: date)!
                
            case 5:
                // Trigger explode notification (project past its deadline)
                startedAt = calendar.date(byAdding: .day, value: -20, to: date)!
                deadline = calendar.date(byAdding: .day, value: -1, to: date)!
                
            default:
                startedAt = registedAt
                deadline = registedAt
            }
            
            let project = ProjectObject(
                projectId: projectId,
                userId: userId,
                title: titles[i - 1],
                status: .ongoing,
                todos: [],
                totalRegistedTodo: 0,
                dailyRegistedTodo: 5,
                finishedTodo: 0,
                alerted: 1,
                extendedCount: i <= 3 ? 5 : 0,
                registedAt: registedAt,
                startedAt: startedAt,
                deadline: deadline,
                finishedAt: registedAt,
                syncedAt: registedAt
            )
            self.mockProjects.append(project)
        }
        return true
    }
}

//MARK: Set at storage

extension MockGenerator {

    private func setDataExecutor() -> Bool {
        let context = storageManager.context
        var results = [Bool]()
        
        context.performAndWait {
            results = [
                setMockStatAtLocal(context),
                setMockAccessLogsAtLocal(context),
                setMockProjectsAtLocal(context)
            ]
        }
        if results.allSatisfy({ $0 }) {
            return storageManager.saveContext()
        } else {
            print("[MockGen] Failed to set mock data at storage")
            return false
        }
    }
    
    private func setMockStatAtLocal(_ context: NSManagedObjectContext) -> Bool {
        do {
            return try statCD.updateObject(context: context, dto: mockStat)
        } catch {
            print("[MockGen] Failed to set stat mock data")
            return false
        }
    }
    
    private func setMockProjectsAtLocal(_ context: NSManagedObjectContext) -> Bool {
        var results = [Bool]()
        for project in mockProjects {
            results.append(projectCD.setObject(context: context, object: project))
        }
        return results.allSatisfy{$0}
    }
    
    private func setMockAccessLogsAtLocal(_ context: NSManagedObjectContext) -> Bool {
        var results = [Bool]()
        for log in mockAccessLog {
            results.append(accessLogCD.setObject(context: context, object: log))
        }
        return results.allSatisfy{$0}
    }
}

