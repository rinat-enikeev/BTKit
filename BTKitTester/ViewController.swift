//
//  ViewController.swift
//  BTKitTester
//
//  Created by Rinat Enikeev on 6/9/19.
//  Copyright © 2019 Rinat Enikeev. All rights reserved.
//

import UIKit
import BTKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        BTKit.scanner.scan(self) { (observer, device) in
            if let tag = device.ruuvi?.tag, tag.isConnectable {
                BTKit.scanner.connect(observer, uuid: tag.uuid, closure: { (observer, device) in
                    print(device)
                })
            }
        }
    }
}

