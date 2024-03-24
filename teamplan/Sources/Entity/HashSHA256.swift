//
//  HashSHA256.swift
//  teamplan
//
//  Created by 크로스벨 on 4/3/24.
//  Copyright © 2024 team1os. All rights reserved.
//

import Foundation
import CryptoKit

final class HashSHA256 {
    func hash(_ input: String?) -> String {
        guard let input else { return "" }
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
}
