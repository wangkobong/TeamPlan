//
//  Interceptor.swift
//  투두팡
//
//  Created by sungyeon on 1/9/25.
//  Copyright © 2025 team1os. All rights reserved.
//

import Foundation
import Alamofire

class CustomRequestInterceptor: RequestInterceptor {
    func adapt(_ urlRequest: URLRequest,
              for session: Session,
              completion: @escaping (Result<URLRequest, Error>) -> Void) {
        var urlRequest = urlRequest
        // 요청 수정 로직
        completion(.success(urlRequest))
    }
    
    func retry(_ request: Request,
              for session: Session,
              dueTo error: Error,
              completion: @escaping (RetryResult) -> Void) {
        // 재시도 로직
        guard let response = request.response else {
            completion(.doNotRetry)
            return
        }
        
        // 토큰 만료시 갱신 후 재시도
        if response.statusCode == 401 {
            Task {
                do {
                    try await refreshToken()
                    completion(.retry)
                } catch {
                    completion(.doNotRetry)
                }
            }
        } else {
            completion(.doNotRetry)
        }
    }
}

extension CustomRequestInterceptor {
    private func refreshToken() {
        
    }
}
