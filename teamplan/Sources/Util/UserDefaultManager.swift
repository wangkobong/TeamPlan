//
//  UserDefaultManager.swift
//  teamplan
//
//  Created by sungyeon on 2023/11/17.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation

final class UserDefaultManager {

    var userName: String?
    var identifier: String?
    
    private let key: String = UserDefaultKey.user.rawValue
    
    private init(name: String?, identifier: String?) {
        self.userName = name
        self.identifier = identifier
    }

    static func loadWith() -> UserDefaultManager? {
        guard let data = UserDefaults.standard.data(forKey: UserDefaultKey.user.rawValue),
              let decoded = try? JSONDecoder().decode(UserDefaultManager.self, from: data)
        else {
            print("[UserDefault] Failed to load UserDefault")
            return nil
        }
        return decoded
    }
    
    static func createWith() -> UserDefaultManager? {
        let newUserDefaultManager = UserDefaultManager(name: nil, identifier: nil)
        if newUserDefaultManager.save() {
            return newUserDefaultManager
        } else {
            print("[UserDefault] Failed to create UserDefault")
            return nil
        }
    }
    
    func save() -> Bool {
        do {
            let data = try JSONEncoder().encode(self)
            UserDefaults.standard.set(data, forKey: self.key)
            return true
        } catch {
            print("[UserDefault] Failed to save UserDefaultManager: \(error.localizedDescription)")
            return false
        }
    }
    
    func clear() {
        UserDefaults.standard.removeObject(forKey: self.key)
    }
}

extension UserDefaultManager: Codable {
    
    enum CodingKeys: CodingKey {
        case userName, identifier
    }
    
    convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let userName = try container.decodeIfPresent(String.self, forKey: .userName)
        let identifier = try container.decodeIfPresent(String.self, forKey: .identifier)
        self.init(name: userName, identifier: identifier)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(self.userName, forKey: .userName)
        try container.encodeIfPresent(self.identifier, forKey: .identifier)
    }
}

enum UserDefaultKey: String {
    case user = "user"
}
