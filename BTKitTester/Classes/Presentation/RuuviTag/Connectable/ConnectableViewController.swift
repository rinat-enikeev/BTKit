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
    @IBOutlet weak var disconnectButton: UIButton!
    @IBOutlet weak var temperatureButton: UIButton!
    @IBOutlet weak var humidityButton: UIButton!
    @IBOutlet weak var pressureButton: UIButton!
    
    var isConnected: Bool = false { didSet { updateUIIsConnected() } }
    var isReading: Bool = false { didSet { updateUIIsReading() } }
    
    private var values = [(Date,Double)]()
    private var connectToken: ObservationToken?
    private var disconnectToken: ObservationToken?
    private var temperatureToken: ObservationToken?
    private var humidityToken: ObservationToken?
    private var pressureToken: ObservationToken?
    private let cellReuseIdentifier = "ConnectableTableViewCellReuseIdentifier"
    private lazy var timeFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "HH:mm:ss"
        return df
    }()
    
    deinit {
        connectToken?.invalidate()
        disconnectToken?.invalidate()
        temperatureToken?.invalidate()
        humidityToken?.invalidate()
        pressureToken?.invalidate()
    }
    
}

// MARK: - IBActions
extension ConnectableViewController {
    @IBAction func connectButtonTouchUpInside(_ sender: Any) {
        connectToken?.invalidate()
        connectToken = ruuviTag.connect(for: self, result: { (observer, result) in
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
        })
    }
    
    @IBAction func disconnectButtonTouchUpInside(_ sender: Any) {
        connectToken?.invalidate()
        disconnectToken?.invalidate()
        BTKit.scanner.disconnect(self, uuid: ruuviTag.uuid) { (observer) in
            observer.isConnected = false
        }
    }
    
    @IBAction func temperatureButtonTouchUpInside(_ sender: Any) {
        if let from = Calendar.current.date(byAdding: .minute, value: -5, to: Date()) {
            temperatureToken?.invalidate()
            isReading = true
            temperatureToken = ruuviTag.celisus(for: self, from: from) { [weak self] (result) in
                self?.isReading = false
                self?.temperatureToken?.invalidate()
                switch result {
                case .success(let values):
                    self?.values = values
                    self?.tableView.reloadData()
                case .failure(let error):
                    print(error.localizedDescription)
                }
            }
        }
    }
    
    @IBAction func humidityButtonTouchUpInside(_ sender: Any) {
        if let from = Calendar.current.date(byAdding: .minute, value: -5, to: Date()) {
            humidityToken?.invalidate()
            isReading = true
            humidityToken = ruuviTag.humidity(for: self, from: from) { [weak self] (result) in
                self?.isReading = false
                self?.humidityToken?.invalidate()
                switch result {
                case .success(let values):
                    self?.values = values
                    self?.tableView.reloadData()
                case .failure(let error):
                    print(error.localizedDescription)
                }
            }
        }
    }
    
    @IBAction func pressureButtonTouchUpInside(_ sender: Any) {
        if let from = Calendar.current.date(byAdding: .minute, value: -5, to: Date()) {
            pressureToken?.invalidate()
            isReading = true
            pressureToken = ruuviTag.pressure(for: self, from: from) { [weak self] (result) in
                self?.isReading = false
                self?.pressureToken?.invalidate()
                switch result {
                case .success(let values):
                    self?.values = values
                    self?.tableView.reloadData()
                case .failure(let error):
                    print(error.localizedDescription)
                }
            }
        }
        
    }
}

// MARK: - View lifecycle
extension ConnectableViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        isConnected = ruuviTag.isConnected
        updateUI()
    }
}

// MARK: - UITableViewDataSource
extension ConnectableViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return values.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier, for: indexPath) as! ConnectableTableViewCell
        let value = values[indexPath.row]
        cell.timeLabel.text = timeFormatter.string(from: value.0)
        cell.valueLabel.text = String(format: "%0.2f", value.1)
        return cell
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
            disconnectButton.isEnabled = isConnected
            temperatureButton.isEnabled = isConnected
            humidityButton.isEnabled = isConnected
            pressureButton.isEnabled = isConnected
        }
    }
    
    private func updateUIIsReading() {
        if isViewLoaded {
            temperatureButton.isEnabled = !isReading && isConnected
            humidityButton.isEnabled = !isReading && isConnected
            pressureButton.isEnabled = !isReading && isConnected
        }
    }
}
