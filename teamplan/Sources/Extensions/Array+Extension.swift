//
//  Array+Extension.swift
//  teamplan
//
//  Created by sungyeon on 2023/11/29.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation

extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
