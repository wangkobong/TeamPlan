//
//  ProjectMock.swift
//  teamplan
//
//  Created by 크로스벨 on 6/6/24.
//  Copyright © 2024 team1os. All rights reserved.
//

import Foundation

final class ProjectMock {
    func createMockProjects() -> [ProjectObject] {
        let userId = "testUser"
        let today = Date()
        let calendar = Calendar.current
        
        // Halfway point
        let halfwayStart = calendar.date(byAdding: .day, value: -7, to: today)!
        let halfwayDeadline = calendar.date(byAdding: .day, value: 7, to: today)!
        
        // Near deadline (3/4 point)
        let nearDeadlineStart = calendar.date(byAdding: .day, value: -14, to: today)!
        let nearDeadline = calendar.date(byAdding: .day, value: 2, to: today)!
        
        // One day left
        let oneDayLeftStart = calendar.date(byAdding: .day, value: -6, to: today)!
        let oneDayLeftDeadline = calendar.date(byAdding: .day, value: 1, to: today)!
        
        // The day of deadline
        let theDayStart = calendar.date(byAdding: .day, value: -7, to: today)!
        let theDayDeadline = today
        
        // Exploded (past deadline)
        let explodedStart = calendar.date(byAdding: .day, value: -10, to: today)!
        let explodedDeadline = calendar.date(byAdding: .day, value: -1, to: today)!
        
        return [
            ProjectObject(projectId: 1, userId: userId, title: "Halfway Project", status: .ongoing, todos: [], totalRegistedTodo: 10, dailyRegistedTodo: 1, finishedTodo: 5, alerted: 0, extendedCount: 0, registedAt: halfwayStart, startedAt: halfwayStart, deadline: halfwayDeadline, finishedAt: Date(), syncedAt: Date()),
            
            ProjectObject(projectId: 2, userId: userId, title: "Near Deadline Project", status: .ongoing, todos: [], totalRegistedTodo: 10, dailyRegistedTodo: 1, finishedTodo: 7, alerted: 0, extendedCount: 0, registedAt: nearDeadlineStart, startedAt: nearDeadlineStart, deadline: nearDeadline, finishedAt: Date(), syncedAt: Date()),
            
            ProjectObject(projectId: 3, userId: userId, title: "One Day Left Project", status: .ongoing, todos: [], totalRegistedTodo: 10, dailyRegistedTodo: 1, finishedTodo: 8, alerted: 0, extendedCount: 0, registedAt: oneDayLeftStart, startedAt: oneDayLeftStart, deadline: oneDayLeftDeadline, finishedAt: Date(), syncedAt: Date()),
            
            ProjectObject(projectId: 4, userId: userId, title: "The Day Project", status: .ongoing, todos: [], totalRegistedTodo: 10, dailyRegistedTodo: 1, finishedTodo: 9, alerted: 0, extendedCount: 0, registedAt: theDayStart, startedAt: theDayStart, deadline: theDayDeadline, finishedAt: Date(), syncedAt: Date()),
            
            ProjectObject(projectId: 5, userId: userId, title: "Exploded Project", status: .exploded, todos: [], totalRegistedTodo: 10, dailyRegistedTodo: 1, finishedTodo: 10, alerted: 0, extendedCount: 0, registedAt: explodedStart, startedAt: explodedStart, deadline: explodedDeadline, finishedAt: Date(), syncedAt: Date())
        ]
    }
}
