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
    private let baseURL = "http://todopang.uk"
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
            "accept": "application/json"
        ]
        
        if let token = token {
            headers["Token"] = token
        }
        
        // Request 로깅
        print("🚀 Request URL: \(url)")
        print("📤 Request Method: \(endpoint.method.rawValue)")
        print("📤 Request Headers: \(headers)")
        if let parameters = endpoint.parameters {
            print("📦 Request Parameters: \(parameters)")
        }
        
        do {
            let request = session.request(
                url,
                method: endpoint.method,
                parameters: endpoint.parameters,
                encoding: JSONEncoding.default,
                headers: headers
            )
            
            let data = try await request.validate().serializingData().value
            
            // Response 로깅
            print("📥 Response Status Code: \(request.response?.statusCode ?? 0)")
            if let json = try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as? [String: Any] {
                print("📥 Response Data: \(json)")
            }
            
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            print("❌ Network Error: \(error)")
            throw error
        }
    }
}
