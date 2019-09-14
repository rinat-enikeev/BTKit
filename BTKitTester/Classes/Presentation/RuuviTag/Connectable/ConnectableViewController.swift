//
//  ConnectableViewController.swift
//  BTKitTester
//
//  Created by Rinat Enikeev on 9/12/19.
//  Copyright © 2019 Rinat Enikeev. All rights reserved.
//

import UIKit
import BTKit
import CoreBluetooth

class ConnectableViewController: UITableViewController {
    var ruuviTag: RuuviTag!
    
    @IBOutlet weak var uuidOrMacLabel: UILabel!
    @IBOutlet weak var connectButton: UIButton!
    @IBOutlet weak var readButton: UIButton!
    
    var isConnected: Bool = false { didSet { updateUIIsConnected() } }
    var isReading: Bool = false { didSet { updateUIIsReading() } }
    
    private var connectToken: ObservationToken?
    private var readToken: ObservationToken?
    
    deinit {
        connectToken?.invalidate()
        readToken?.invalidate()
    }
}

// MARK: - IBActions
extension ConnectableViewController {
    @IBAction func connectButtonTouchUpInside(_ sender: Any) {
        connectToken?.invalidate()
        connectToken = BTKit.scanner.connect(self, uuid: ruuviTag.uuid, connected: { (observer) in
            observer.isConnected = true
        }) { (observer) in
            observer.isConnected = false
        }
    }
    
    @IBAction func readButtonTouchUpInside(_ sender: Any) {
        if let from = Calendar.current.date(byAdding: .hour, value: -5, to: Date()) {
            readToken?.invalidate()
            isReading = true
            readToken = ruuviTag.celisus(for: self, from: from) { [weak self] (result) in
                self?.isReading = false
                self?.readToken?.invalidate()
                switch result {
                case .success(let values):
                    print(values)
                case .failure(let error):
                    print(error)
                }
            }
        }
    }
}

// MARK: - View lifecycle
extension ConnectableViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        updateUI()
    }
}

// MARK: - Update UI
extension ConnectableViewController {
    private func updateUI() {
        updateUIUUIDOrMAC()
        updateUIIsConnected()
        updateUIIsReading()
    }
    
    private func updateUIUUIDOrMAC() {
        if isViewLoaded {
            uuidOrMacLabel.text = ruuviTag.mac ?? ruuviTag.uuid
        }
    }
    
    private func updateUIIsConnected() {
        if isViewLoaded {
            connectButton.isEnabled = !isConnected
            readButton.isEnabled = isConnected
        }
    }
    
    private func updateUIIsReading() {
        if isViewLoaded {
            readButton.isEnabled = !isReading && isConnected
        }
    }
}
