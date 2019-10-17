//
//  HeartbeatPersistence.swift
//  BTKitTester
//
//  Created by Rinat Enikeev on 10/17/19.
//  Copyright © 2019 Rinat Enikeev. All rights reserved.
//

import Foundation

protocol HeartbeatPersistence {
    func persist(uuid: String)
    func remove(uuid: String)
    func contains(uuid: String) -> Bool
    func all() -> [String]?
}
