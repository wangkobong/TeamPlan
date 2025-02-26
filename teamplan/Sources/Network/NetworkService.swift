//
//  NetworkService.swift
//  투두팡
//
//  Created by sungyeon on 1/9/25.
//  Copyright © 2025 team1os. All rights reserved.
//

import Foundation
import Alamofire

class NetworkService {
    private let baseURL = "https://todopang.uk"
    private let session: Session
    private var token: String?
    
    init(token: String? = nil) {
        self.token = token
        
        // 기본 설정
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 300
        
        // 인터셉터 설정
        let interceptor = CustomRequestInterceptor()
        
        self.session = Session(configuration: configuration,
                               interceptor: interceptor)
    }
    
    // 토큰 설정 메서드
    func setToken(_ token: String) {
        self.token = token
    }
    
    // 기본 요청 메서드
    func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T {
        let url = baseURL + endpoint.path
            
            var headers: HTTPHeaders = [
                "Content-Type": "application/json",
                "accept": "application/json",
            ]
            
            if let token = token {
                headers["Authorization"] = "Bearer \(token)"
            }
            
            print("🚀 Request URL: \(url)")
            print("📤 Request Method: \(endpoint.method.rawValue)")
            print("📤 Request Headers: \(headers)")
        
            // 파라미터 프린트 추가
            if let parameters = endpoint.parameters {
                print("📤 Request Parameters: \(parameters)")
            } else {
                print("📤 Request Parameters: None")
            }
            
             let response = try await AF.request(
                url,
                method: endpoint.method,
                parameters: endpoint.parameters,
                encoding: JSONEncoding.default,
                headers: headers
             )
             .validate()
             .serializingDecodable(T.self)
             .response

             print("📥 Response Status Code:", response.response?.statusCode ?? 0)
             print("📥 Response Data:", String(data: response.data ?? Data(), encoding: .utf8) ?? "")

             return try JSONDecoder().decode(T.self, from: response.data ?? Data())

    }
}
