//
//  Utilities.swift
//  teamplan
//
//  Created by sungyeon kim on 2023/06/01.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation

final class Utilities {
    
    //============================
    // MARK: Get Identifier
    //============================
    func getIdentifier(authRes: AuthSocialLoginResDTO,
                       result: @escaping(Result<String, Error>) -> Void) {
        
        self.getAccountName(userEmail: authRes.email) { res in
            switch res {
                
            // create identifier
            case .success(let nickName):
                let identifier = "\(nickName)_\(authRes.provider.rawValue)"
                return result(.success(identifier))
                
            // Exception Handling: Invalid Email Format
            case .failure(let error):
                return result(.failure(error))
            }
        }
    }
    
    //============================
    // MARK: Extract AccountName
    //============================
    func getAccountName(userEmail: String,
                        result: @escaping(Result<String, Error>) -> Void) {
        guard let atIndex = userEmail.firstIndex(of: "@"), atIndex != userEmail.startIndex else {
            return result(.failure(EmailError.invalidEmailFormat))
        }
        return result(.success(String(userEmail.prefix(upTo: atIndex))))
    }

    enum EmailError: LocalizedError {
        case invalidEmailFormat
        
        var errorDescription: String? {
            switch self {
            case .invalidEmailFormat:
                return "Invalid email format"
            }
        }
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
    
    //============================
    // MARK: Updated Field Check
    //============================
    func updateFieldIfNeeded<T: Equatable>(_ currentValue: inout T, newValue: T) -> Bool {
        if currentValue != newValue {
            currentValue = newValue
            return true
        }
        return false
    }
}
