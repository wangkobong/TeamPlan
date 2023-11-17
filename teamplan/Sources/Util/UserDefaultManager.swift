//
//  UserDefaultManager.swift
//  teamplan
//
//  Created by sungyeon on 2023/11/17.
//  Copyright © 2023 team1os. All rights reserved.
//

import Foundation

class UserDefaultManager: Codable {
    
    private var key: String = ""
    
    var userName: String? {didSet { save() }}
    var identifier: String? {didSet { save() }}
    
    enum CodingKeys: String, CodingKey {
        case userName
        case identifier
    }

    private init(key: String) {
        self.key = key
    }
}

// MARK: Creation
extension UserDefaultManager {
    
    static func loadWith(key: String) -> UserDefaultManager? {
        var item = UserDefaultManager.loadForKey(key)
        item?.key = key
        if item == nil { item = UserDefaultManager(key: key) }
        return item
    }
}

// MARK: Load and Save
private extension UserDefaultManager {
    
    static func loadForKey(_ key: String) -> Self? {
        let defaults = UserDefaults.standard
        let decoder = JSONDecoder()
        if let savedObject = defaults.object(forKey: key) as? Data,
           let loadedObject = try? decoder.decode(Self.self, from: savedObject) {
            return loadedObject
        }
        return nil
    }
    
    func save() {
        let defaults = UserDefaults.standard
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(self) {
            defaults.set(encoded, forKey: key)
        }
    }
}
