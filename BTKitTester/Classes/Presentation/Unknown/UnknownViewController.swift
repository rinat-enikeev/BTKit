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
    
    @IBOutlet weak var disconnectButton: UIButton!
    @IBOutlet weak var connectButton: UIButton!
    @IBOutlet weak var nameLabel: UILabel!
    
    var device: BTUnknownDevice!
    
    var isConnected: Bool = false { didSet { updateUIIsConnected() } }
    
    private var connectToken: ObservationToken?
    private var disconnectToken: ObservationToken?
    
    deinit {
        connectToken?.invalidate()
        disconnectToken?.invalidate()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        isConnected = device.isConnected
        updateUI()
    }
    
    @IBAction func connectButtonTouchUpInside(_ sender: Any) {
        connectToken?.invalidate()
        connectToken = BTKit.connection.establish(for: self, uuid: device.uuid) { (observer, result) in
            switch result {
            case .already:
                observer.isConnected = true
            case .just:
                observer.isConnected = true
            case .disconnected:
                observer.isConnected = false
            case .failure(let error):
                print(error.localizedDescription)
                observer.isConnected = false
            }
        }
    }
    
    
    @IBAction func disconnectButtonTouchUpInside(_ sender: Any) {
        connectToken?.invalidate()
        disconnectToken?.invalidate()
        disconnectToken = BTKit.connection.drop(for: self, uuid: device.uuid) { (observer, result) in
            observer.disconnectToken?.invalidate()
            switch result {
            case .just:
                observer.isConnected = false
            case .already:
                observer.isConnected = false
            case .failure(let error):
                observer.isConnected = false
                print(error.localizedDescription)
            }
        }
    }
    
    private func updateUI() {
        updateUIIsConnected()
    }
    
    private func updateUIIsConnected() {
        if isViewLoaded {
            connectButton.isEnabled = !isConnected
            disconnectButton.isEnabled = isConnected
        }
    }
}
