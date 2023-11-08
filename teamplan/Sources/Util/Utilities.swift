//
//  Utilities.swift
//  teamplan
//
//  Created by sungyeon kim on 2023/06/01.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation

enum EmailError: LocalizedError {
    case invalidEmailFormat
    
    var errorDescription: String? {
        switch self {
        case .invalidEmailFormat:
            return "Invalid email format"
        }
    }
}

final class Utilities {
    
    //============================
    // MARK: Get Identifier
    //============================
    func getIdentifier(authRes: AuthSocialLoginResDTO,
                       result: @escaping(Result<String, Error>) -> Void) {
        
        let accountName = self.getAccountName(userEmail: authRes.email)
        
        if accountName == "" {
            return result(.failure(EmailError.invalidEmailFormat))
        } else {
            let identifier = "\(accountName)_\(authRes.provider.rawValue)"
            return result(.success(identifier))
        }

    }
    
    //============================
    // MARK: Extract AccountName
    //============================
//    func getAccountName(userEmail: String,
//                        result: @escaping(Result<String, Error>) -> Void) {
//        guard let atIndex = userEmail.firstIndex(of: "@"), atIndex != userEmail.startIndex else {
//            return result(.failure(EmailError.invalidEmailFormat))
//        }
//        return result(.success(String(userEmail.prefix(upTo: atIndex))))
//    }
//
    func getAccountName(userEmail: String) -> String {
        guard let atIndex = userEmail.firstIndex(of: "@"), atIndex != userEmail.startIndex else {
            return ""
        }
        return (String(userEmail.prefix(upTo: atIndex)))
    }

    //============================
    // MARK: Time Calculation
    //============================
    func calcTime(currentTime: Date, lastTime: Date) -> Bool {
        
        let calendar = Calendar.current
        let lastTimeComp = calendar.dateComponents([.year, .month, .day], from: lastTime)
        let currentTimeComp = calendar.dateComponents([.year, .month, .day], from: currentTime)
        
        if let lastTimeDay = calendar.date(from: lastTimeComp),
           let currentTimeDay = calendar.date(from: currentTimeComp),
           
            currentTimeDay <= lastTimeDay {
            return true
        } else {
            return false
        }
    }
}
