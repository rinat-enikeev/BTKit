//
//  HeartbeatPersistenceUserDefaults.swift
//  BTKitTester
//
//  Created by Rinat Enikeev on 10/17/19.
//  Copyright © 2019 Rinat Enikeev. All rights reserved.
//

import Foundation

class HeartbeatPersistenceUserDefaults: HeartbeatPersistence {
    
    static let shared = HeartbeatPersistenceUserDefaults()
    
    private let key = "HeartbeatPersistenceUserDefaultsUDKey"
    
    func persist(uuid: String) {
        if var array = UserDefaults.standard.stringArray(forKey: key) {
            if !array.contains(uuid) {
                array.append(uuid)
                UserDefaults.standard.set(array, forKey: key)
            }
        } else {
            UserDefaults.standard.set([uuid], forKey: key)
        }
    }
    
    func remove(uuid: String) {
        if var array = UserDefaults.standard.stringArray(forKey: key) {
            array.removeAll(where: { $0 == uuid })
            UserDefaults.standard.set(array, forKey: key)
        }
    }
    
    func contains(uuid: String) -> Bool {
        if let array = UserDefaults.standard.stringArray(forKey: key) {
            return array.contains(uuid)
        } else {
            return false
        }
    }
    
    func all() -> [String]? {
        return UserDefaults.standard.stringArray(forKey: key)
    }
    
}
