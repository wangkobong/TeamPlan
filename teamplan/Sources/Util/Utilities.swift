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
    // MARK: Account Helper
    //============================
    // Identifier
    func getIdentifier(from authRes: AuthSocialLoginResDTO) throws -> String {
        
        let accountName = try getAccountName(from: authRes.email)
        return "\(accountName)_\(authRes.provider.rawValue)"
    }
    
    // Account Name
    private func getAccountName(from userEmail: String) throws -> String {
        
        guard let atIndex = userEmail.firstIndex(of: "@"), atIndex != userEmail.startIndex else {
            throw utilError.InvalidEmailFormat
        }
        return (String(userEmail.prefix(upTo: atIndex)))
    }

    //============================
    // MARK: Time Helper
    //============================
    // Compare
    func compareTime(currentTime: Date, lastTime: Date) -> Bool {
        
        let calendar = Calendar.current
        let lastTimeComp = calendar.dateComponents([.year, .month, .day], from: lastTime)
        let currentTimeComp = calendar.dateComponents([.year, .month, .day], from: currentTime)
        
        return lastTimeComp.year == currentTimeComp.year &&
               lastTimeComp.month == currentTimeComp.month &&
               lastTimeComp.day == currentTimeComp.day
    }
    
    //============================
    // MARK: Update Helper
    //============================
    // Check
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
    // Data to JSON
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
    
    // JSON to Data
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
// MARK: Extension
//============================
// Dictionary
extension Dictionary {
    func mapKeys<T: Hashable>(_ transform: (Key) -> T) -> [T: Value] {
        var newDict = [T: Value]()
        for (key, value) in self {
            newDict[transform(key)] = value
        }
        return newDict
    }
}

// DateFormatter
extension DateFormatter {
    static let standardFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        return formatter
    }()
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
