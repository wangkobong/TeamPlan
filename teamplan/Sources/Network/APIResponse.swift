//
//  APIResponse.swift
//  투두팡
//
//  Created by sungyeon on 1/9/25.
//  Copyright © 2025 team1os. All rights reserved.
//

import Foundation

struct APIResponse<T: Codable>: Codable {
   let status: Int
   let result: String
   let message: String
   let data: T?
}
