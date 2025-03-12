//
//  HomeRepository.swift
//  투두팡
//
//  Created by sungyeon kim on 3/12/25.
//  Copyright © 2025 team1os. All rights reserved.
//

import Foundation
import Alamofire

class HomeRepository {
    let networkService: NetworkService

    init(networkService: NetworkService = NetworkService()) {
        self.networkService = networkService
    }
    
    func getHomeData(userId: String) async throws -> HomeData? {
        
        let response: APIResponse<HomeData> = try await networkService.request(.getHomeInfo(userId: userId))
        
        return response.data
    }
}
