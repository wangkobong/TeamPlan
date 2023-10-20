//
//  Utilities.swift
//  teamplan
//
//  Created by sungyeon kim on 2023/06/01.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation

final class Utilities {
    
    //====================
    // MARK: Identifier
    //====================
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
}
