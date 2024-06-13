//
//  Utilities.swift
//  teamplan
//
//  Created by sungyeon kim on 2023/06/01.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation

final class Utilities {
    
    // MARK: Time Calculator
    // Compare
    func compareTime(currentTime: Date, lastTime: Date) -> Bool {
        
        let calendar = Calendar.current
        return calendar.isDate(currentTime, inSameDayAs: lastTime)
    }
    // D-Day
    func calculateDatePeriod(with start: Date, and end: Date) throws -> Int {
        
        // For accurate date calculation, force timezone to UTC
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        
        let startDate = calendar.startOfDay(for: start)
        let endDate = calendar.startOfDay(for: end)
        
        let components = calendar.dateComponents([.day], from: startDate, to: endDate)
        guard let period = components.day else {
            throw UtilError.UnexpectedTimeCalculateError
        }
        return period
    }
    
    // Update Check
    func updateIfNeeded<T: Equatable>(_ currentValue: inout T, newValue: T?) -> Bool {
        guard let newValue = newValue, currentValue != newValue else { return false }
        currentValue = newValue
        return true
    }
    
    
    // MARK: JSON Converter
    // Data to JSON
    func convertToJSON<T: Codable>(data: T) throws -> String {
        do {
            let jsonData = try JSONEncoder().encode(data)
            
            guard let jsonString = String(data: jsonData, encoding: .utf8) else {
                throw UtilError.ToJsonCoversionError
            }
            return jsonString
            
        } catch {
            print("(Util) Error Encode JSON : \(error)")
            throw UtilError.UnexpectedEncodeError
        }
    }
    
    // JSON to Data
    func convertFromJSON<T: Codable>(jsonString: String?, type: T.Type) throws -> T {
        do {
            guard let jsonString = jsonString else {
                throw UtilError.InvalidJsonStringFormat
            }
            guard let jsonData = jsonString.data(using: .utf8) else {
                throw UtilError.FromJsonConversionError
            }
            return try JSONDecoder().decode(T.self, from: jsonData)
        } catch {
            print("(Util) Error Decode JSON : \(error)")
            throw UtilError.UnexpectedDecodeError
        }
    }
}


// MARK: Extension
extension Dictionary {
    func mapKeys<T: Hashable>(transform: (Key) -> T) -> [T: Value] {
        var newDict: [T: Value] = [:]
        for (key, value) in self {
            newDict[transform(key)] = value
        }
        return newDict
    }

    func compactMapKeys<T: Hashable>(transform: (Key) -> T?) -> [T: Value] {
        var newDict: [T: Value] = [:]
        for (key, value) in self {
            if let newKey = transform(key) {
                newDict[newKey] = value
            }
        }
        return newDict
    }
}

extension DateFormatter {
    static let standardFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()
    
    static let shortFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yy.MM.dd"
        return formatter
    }()
}

//================================
// MARK: - Exception
//================================
enum UtilError: LocalizedError {
    case InvalidEmailFormat
    case InvalidJsonStringFormat
    case ToJsonCoversionError
    case FromJsonConversionError
    case UnexpectedEncodeError
    case UnexpectedDecodeError
    case UnexpectedTimeCalculateError
    
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
        case .UnexpectedTimeCalculateError:
            return "There was an unexpected error while Calculate Date Period"
        }
    }
}
