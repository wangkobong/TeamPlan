//
//  TermsModel.swift
//  teamplan
//
//  Created by sungyeon kim on 2023/06/08.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation

struct TermsModel: Identifiable, Hashable {
    let id = UUID().uuidString
    let title: String
    var isSelected: Bool
    let buttonState: ButtonState
}
