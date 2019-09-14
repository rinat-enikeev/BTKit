//
//  Data+Hex.swift
//  BTKitTester
//
//  Created by Rinat Enikeev on 9/14/19.
//  Copyright © 2019 Rinat Enikeev. All rights reserved.
//

import Foundation

extension Data {
    var hexString: String {
        let hexString = map { String(format: "%02.2hhx", $0) }.joined()
        return hexString
    }
}
