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

private enum ConnectableTableSource {
    case values
    case logs
}

class ConnectableViewController: UITableViewController {
    var ruuviTag: RuuviTag!
    
    @IBOutlet weak var uuidOrMacLabel: UILabel!
    @IBOutlet weak var connectButton: UIButton!
    @IBOutlet weak var disconnectButton: UIButton!
    @IBOutlet weak var temperatureButton: UIButton!
    @IBOutlet weak var humidityButton: UIButton!
    @IBOutlet weak var pressureButton: UIButton!
    @IBOutlet weak var allButton: UIButton!
    @IBOutlet weak var unsubscribeButton: UIButton!
    @IBOutlet weak var subscribeButton: UIButton!
    @IBOutlet weak var firmwareButton: UIButton!

    private var isConnected: Bool = false { didSet { updateUIIsConnected() } }
    private var isSubscribed: Bool = false { didSet { updateUIIsSubscribed() } }
    private var isReading: Bool = false { didSet { updateUIIsReading() } }
    
    private let heartbeatService: HeartbeatService = HeartbeatServiceBTKit.shared
    private var source: ConnectableTableSource = .values
    private var values = [RuuviTagEnvLog]()
    private var logs = [RuuviTagEnvLogFull]()
    private var connectToken: ObservationToken?
    private var disconnectToken: ObservationToken?
    private let valueCellReuseIdentifier = "ConnectableValueTableViewCellCellReuseIdentifier"
    private let valuesCellReuseIdentifier = "ConnectableValuesTableViewCellReuseIdentifier"
    private lazy var timeFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "HH:mm:ss"
        return df
    }()
    
    deinit {
        connectToken?.invalidate()
        disconnectToken?.invalidate()
    }

}

// MARK: - IBActions
extension ConnectableViewController {
    @IBAction func firmwareButtonTouchUpInside(_ sender: Any) {

    }

    @IBAction func subscribeButtonTouchUpInside(_ sender: Any) {
        heartbeatService.subscribe(to: ruuviTag.uuid)
        isSubscribed = true
    }
    
    @IBAction func unsubscribeButtonTouchUpInside(_ sender: Any) {
        heartbeatService.unsubscribe(from: ruuviTag.uuid)
        isSubscribed = false
    }
    
    @IBAction func connectButtonTouchUpInside(_ sender: Any) {
        connectToken?.invalidate()
        connectToken = BTKit.background.connect(for: self, uuid: ruuviTag.uuid, connected: { (observer, result) in
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
        disconnectToken = BTKit.background.disconnect(for: self, uuid: ruuviTag.uuid) { (observer, result) in
            observer.disconnectToken?.invalidate()
            switch result {
            case .just:
                observer.isConnected = false
            case .already:
                observer.isConnected = false
            case .stillConnected:
                observer.isConnected = true
            case .bluetoothWasPoweredOff:
                print("bluetooth was powered off")
            case .failure(let error):
                observer.isConnected = false
                print(error.localizedDescription)
            }
        }
    }
    
    @IBAction func temperatureButtonTouchUpInside(_ sender: Any) {
        if let from = Calendar.current.date(byAdding: .minute, value: -5, to: Date()) {
            isReading = true
            BTKit.background.services.ruuvi.nus.celisus(for: self, uuid: ruuviTag.uuid, from: from, result: { (observer, result) in
                observer.isReading = false
                switch result {
                case .success(let values):
                    observer.values = values
                    observer.source = .values
                    observer.tableView.reloadData()
                case .failure(let error):
                    print(error.localizedDescription)
                }
            })
        }
    }
    
    @IBAction func humidityButtonTouchUpInside(_ sender: Any) {
        if let from = Calendar.current.date(byAdding: .minute, value: -5, to: Date()) {
            isReading = true
            BTKit.background.services.ruuvi.nus.humidity(for: self, uuid: ruuviTag.uuid, from: from, result: { (observer, result) in
                observer.isReading = false
                switch result {
                case .success(let values):
                    observer.values = values
                    observer.source = .values
                    observer.tableView.reloadData()
                case .failure(let error):
                    print(error.localizedDescription)
                }
            })
        }
    }
    
    @IBAction func pressureButtonTouchUpInside(_ sender: Any) {
        if let from = Calendar.current.date(byAdding: .minute, value: -5, to: Date()) {
            isReading = true
            BTKit.background.services.ruuvi.nus.pressure(for: self, uuid: ruuviTag.uuid, from: from, result: { (observer, result) in
                observer.isReading = false
                switch result {
                case .success(let values):
                    observer.values = values
                    observer.source = .values
                    observer.tableView.reloadData()
                case .failure(let error):
                    print(error.localizedDescription)
                }
            })
        }
    }
    
    @IBAction func allButtonTouchUpInside(_ sender: Any) {
        if let from = Calendar.current.date(byAdding: .minute, value: -5, to: Date()) {
            isReading = true
            BTKit.background.services.ruuvi.nus.log(for: self, uuid: ruuviTag.uuid, from: from, result: { (observer, result) in
                observer.isReading = false
                switch result {
                case .success(let logs):
                    observer.logs = logs
                    observer.source = .logs
                    observer.tableView.reloadData()
                case .failure(let error):
                    print(error.localizedDescription)
                }
            })
        }
    }
}

// MARK: - View lifecycle
extension ConnectableViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        isConnected = ruuviTag.isConnected
        isSubscribed = heartbeatService.isSubscribed(uuid: ruuviTag.uuid)
        updateUI()
    }
}

// MARK: - UITableViewDataSource
extension ConnectableViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch source {
        case .values:
            return values.count
        case .logs:
            return logs.count
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch source {
        case .values:
            let cell = tableView.dequeueReusableCell(withIdentifier: valueCellReuseIdentifier, for: indexPath) as! ConnectableValueTableViewCell
            let value = values[indexPath.row]
            cell.timeLabel.text = timeFormatter.string(from: value.date)
            cell.valueLabel.text = String(format: "%0.2f", value.value)
            return cell
        case .logs:
            let cell = tableView.dequeueReusableCell(withIdentifier: valuesCellReuseIdentifier, for: indexPath) as! ConnectableValuesTableViewCell
            let log = logs[indexPath.row]
            cell.timeLabel.text = timeFormatter.string(from: log.date)
            cell.temperatureLabel.text = String(format: "%0.2f", log.temperature)
            cell.humidityLabel.text = String(format: "%0.2f", log.humidity)
            cell.pressureLabel.text = String(format: "%0.2f", log.pressure)
            return cell
        }
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
            allButton.isEnabled = isConnected
            firmwareButton.isEnabled = isConnected
        }
    }
    
    private func updateUIIsSubscribed() {
        if isViewLoaded {
            subscribeButton.isEnabled = !isSubscribed
            unsubscribeButton.isEnabled = isSubscribed
        }
    }
    
    private func updateUIIsReading() {
        if isViewLoaded {
            temperatureButton.isEnabled = !isReading && isConnected
            humidityButton.isEnabled = !isReading && isConnected
            pressureButton.isEnabled = !isReading && isConnected
            allButton.isEnabled = !isReading && isConnected
            firmwareButton.isEnabled = !isReading && isConnected
        }
    }
}
