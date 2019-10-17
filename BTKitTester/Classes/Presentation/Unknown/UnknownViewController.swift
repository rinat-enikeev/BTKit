//
//  UnknownViewController.swift
//  BTKitTester
//
//  Created by Rinat Enikeev on 10/16/19.
//  Copyright © 2019 Rinat Enikeev. All rights reserved.
//

import UIKit
import BTKit

class UnknownViewController: UIViewController {
    
    @IBOutlet weak var unsubscribeButton: UIButton!
    @IBOutlet weak var subscribeButton: UIButton!
    @IBOutlet weak var nameLabel: UILabel!
    
    var device: BTUnknownDevice!
    
    private var isSubscribed: Bool = false { didSet { updateUIIsSubscribed() } }
    private let heartbeatService: HeartbeatService = HeartbeatServiceBTKit.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        isSubscribed = heartbeatService.isSubscribed(uuid: device.uuid)
        updateUI()
    }
    
    @IBAction func subscribeButtonTouchUpInside(_ sender: Any) {
        heartbeatService.subscribe(to: device.uuid)
        isSubscribed = true
    }
    
    @IBAction func terminateButtonTouchUpInside(_ sender: Any) {
        exit(0)
    }
    
    @IBAction func unsubscribeButtonTouchUpInside(_ sender: Any) {
        heartbeatService.unsubscribe(from: device.uuid)
        isSubscribed = false
    }
    
    private func updateUI() {
        updateUIIsSubscribed()
        updateName()
    }
    
    private func updateUIIsSubscribed() {
        if isViewLoaded {
            subscribeButton.isEnabled = !isSubscribed
            unsubscribeButton.isEnabled = isSubscribed
        }
    }
    
    private func updateName() {
        if isViewLoaded {
            nameLabel.text = device.name ?? device.uuid
        }
    }
}
