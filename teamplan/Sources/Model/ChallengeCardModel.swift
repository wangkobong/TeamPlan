//
//  ChallengeCardModel.swift
//  teamplan
//
//  Created by sungyeon kim on 2023/08/07.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation

struct ChallengeCardModel: Identifiable, Hashable {
    let id = UUID().uuidString
    let image: String
    let title: String
    let description: String
    let isFinished: Bool = false
}
