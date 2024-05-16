//
//  UserDefaultManager.swift
//  teamplan
//
//  Created by sungyeon on 2023/11/17.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation

final class UserDefaultManager {
    
    private let key: String
    
    var userName: String?
    var identifier: String?
    
    private init(key: String, name: String?, identifier: String?) {
        self.key = key
        self.userName = name
        self.identifier = identifier
    }
    
    static func loadWith(key: String) -> UserDefaultManager? {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode(UserDefaultManager.self, from: data) else {
            return nil
        }
        return decoded
    }
    
    static func createWith(key: String) -> UserDefaultManager {
        let newUserDefaultManager = UserDefaultManager(key: key)
        newUserDefaultManager.save()
        return newUserDefaultManager
    }
    
    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        UserDefaults.standard.set(data, forKey: self.key)
    }
    
    func clear(key: String) {
        UserDefaults.standard.removeObject(forKey: key)
    }

    private init(key: String) {
        self.key = key
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
        let key = UserDefaults.standard.string(forKey: "key") ?? UUID().uuidString
        self.init(key: key, name: userName, identifier: identifier)
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
