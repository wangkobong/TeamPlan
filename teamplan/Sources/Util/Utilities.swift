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
        
        self.getAccountName(userEmail: authRes.email) { res in
            switch res {
                
            // create identifier
            case .success(let nickName):
                let identifier = "\(nickName)_\(authRes.provider.rawValue)"
                return result(.success(identifier))
                
            // Exception Handling: Invalid Email Format
            case .failure(let error):
                print("Error extract Identifier : \(error)")
                return result(.failure(error))
            }
        }
    }
    
    //============================
    // MARK: Extract AccountName
    //============================
    private func getAccountName(userEmail: String,
                        result: @escaping(Result<String, Error>) -> Void) {
        guard let atIndex = userEmail.firstIndex(of: "@"), atIndex != userEmail.startIndex else {
            return result(.failure(utilError.InvalidEmailFormat))
        }
        return result(.success(String(userEmail.prefix(upTo: atIndex))))
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
    
    //============================
    // MARK: JSON Converter
    //============================
    // Convert Data to JSONString
    func convertToJSON<T: Codable>(data: T) throws -> String {
        do {
            let jsonData = try JSONEncoder().encode(data)
            
            guard let jsonString = String(data: jsonData, encoding: .utf8) else {
                throw utilError.ToJsonCoversionError
            }
            return jsonString
            
        } catch {
            print("(Util) Error Encode JSON : \(error)")
            throw utilError.UnexpectedEncodeError
        }
    }
    
    // Convert JSONString to Origin Data
    func convertFromJSON<T: Codable>(jsonString: String?, type: T.Type) throws -> T {
        do {
            guard let jsonString = jsonString else {
                throw utilError.InvalidJsonStringFormat
            }
            guard let jsonData = jsonString.data(using: .utf8) else {
                throw utilError.FromJsonConversionError
            }
            return try JSONDecoder().decode(T.self, from: jsonData)
        } catch {
            print("(Util) Error Decode JSON : \(error)")
            throw utilError.UnexpectedDecodeError
        }
    }
}

//============================
// MARK: Dictionary Extension
//============================
extension Dictionary {
    func mapKeys<T: Hashable>(_ transform: (Key) -> T) -> [T: Value] {
        var newDict = [T: Value]()
        for (key, value) in self {
            newDict[transform(key)] = value
        }
        return newDict
    }
}

//================================
// MARK: - Exception
//================================
enum utilError: LocalizedError {
    case InvalidEmailFormat
    case InvalidJsonStringFormat
    case ToJsonCoversionError
    case FromJsonConversionError
    case UnexpectedEncodeError
    case UnexpectedDecodeError
    
    var errorDescription: String? {
        switch self {
        case .InvalidEmailFormat:
            return "Failed to Extract Identifier: Invalid Email Format "
        case .InvalidJsonStringFormat:
            return "Invalid JSON String foramt Detected"
        case .ToJsonCoversionError:
            return "Failed to Convert Data to JSON"
        case .FromJsonConversionError:
            return "Failed to Convert Data From JSON"
        case .UnexpectedEncodeError:
            return "There was an unexpected error while Encode JSON"
        case .UnexpectedDecodeError:
            return "There was an unexpected error while Decode JSON"
        }
    }
}
