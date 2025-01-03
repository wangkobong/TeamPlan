//
//  ProjectModel.swift
//  teamplan
//
//  Created by sungyeon on 2024/02/01.
//  Copyright © 2024 team1os. All rights reserved.
//

import Foundation

struct ProjectModel: Identifiable, Hashable {
    let id = UUID().uuidString
    let name: String
    let startDate: Int
    let endDate: Int
    var toDos: [ToDo]
}

struct ToDo: Identifiable, Hashable {
    let id = UUID().uuidString
    let name: String
    let isDone: Bool
}
