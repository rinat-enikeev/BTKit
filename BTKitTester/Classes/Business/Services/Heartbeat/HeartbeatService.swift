//
//  HeartbeatService.swift
//  BTKitTester
//
//  Created by Rinat Enikeev on 10/17/19.
//  Copyright © 2019 Rinat Enikeev. All rights reserved.
//

import Foundation

protocol HeartbeatService {
    func subscribe(to uuid: String)
    func unsubscribe(from uuid: String)
    func isSubscribed(uuid: String) -> Bool
    func restore()
}
