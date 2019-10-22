//
//  MainViewController.swift
//  BTKitTester
//
//  Created by Rinat Enikeev on 6/9/19.
//  Copyright © 2019 Rinat Enikeev. All rights reserved.
//

import UIKit
import BTKit
import UserNotifications

enum MainSection: Int, CaseIterable {
    case ruuvi = 0
    case unknown = 1
}

class MainViewController: UITableViewController {

    private var ruuviTags: [RuuviTag] = [RuuviTag]()
    private var ruuviTagsSet: Set<RuuviTag> = Set<RuuviTag>()
    private var unknowns: [BTUnknownDevice] = [BTUnknownDevice]()
    private var unknownSet: Set<BTUnknownDevice> = Set<BTUnknownDevice>()
    private var scanToken: ObservationToken?
    private var unknownToken: ObservationToken?
    private let ruuviCellReuseIdentifier = "MainRuuviTableViewCellReuseIdentifier"
    private let unknownCellReuseIdentifier = "MainUnknownTableViewCellReuseIdentifier"
    private var reloadingTimer: Timer?
    
    deinit {
        scanToken?.invalidate()
        unknownToken?.invalidate()
        reloadingTimer?.invalidate()
    }
}

// MARK: - View lifecycle
extension MainViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) {
            (granted, error) in
            if granted {
                print("yes")
            } else {
                print("No")
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startObserving()
        startReloading()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopObserving()
        stopReloading()
    }
}

// MARK: - UITableViewDataSource
extension MainViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return MainSection.allCases.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case MainSection.ruuvi.rawValue:
            return ruuviTags.count
        case MainSection.unknown.rawValue:
            return unknowns.count
        default:
            fatalError()
        }
        
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case MainSection.ruuvi.rawValue:
            let cell = tableView.dequeueReusableCell(withIdentifier: ruuviCellReuseIdentifier, for: indexPath) as! MainRuuviTableViewCell
            let ruuviTag = ruuviTags[indexPath.row]
            configure(cell: cell, ruuviTag: ruuviTag)
            return cell
        case MainSection.unknown.rawValue:
            let cell = tableView.dequeueReusableCell(withIdentifier: unknownCellReuseIdentifier, for: indexPath) as! MainUnknownTableViewCell
            let unknownDevice = unknowns[indexPath.row]
            configure(cell: cell, unknownDevice: unknownDevice)
            return cell
        default:
            fatalError()
        }
        
    }
    
    private func configure(cell: MainRuuviTableViewCell, ruuviTag: RuuviTag) {
        cell.uuidOrMacLabel.text = ruuviTag.mac ?? ruuviTag.uuid
        cell.accessoryType = ruuviTag.isConnectable ? .detailDisclosureButton : .none
    }
    
    private func configure(cell: MainUnknownTableViewCell, unknownDevice: BTUnknownDevice) {
        cell.nameLabel.text = unknownDevice.name ?? unknownDevice.uuid
        cell.accessoryType = unknownDevice.isConnectable ? .detailDisclosureButton : .none
    }
}

// MARK: - UITableViewDelegate
extension MainViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch indexPath.section {
        case MainSection.ruuvi.rawValue:
            let ruuviTag = ruuviTags[indexPath.row]
            if ruuviTag.isConnectable {
                openConnectable(ruuviTag: ruuviTag)
            }
        case MainSection.unknown.rawValue:
            let device = unknowns[indexPath.row]
            if device.isConnectable {
                openUnknown(device: device)
            }
        default:
            fatalError()
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case MainSection.ruuvi.rawValue:
            return "Ruuvi"
        case MainSection.unknown.rawValue:
            return "Unknown"
        default:
            return nil
        }
    }
}

// MARK: - Routing
extension MainViewController {
    private func openConnectable(ruuviTag: RuuviTag) {
        let storyboard = UIStoryboard(name: "Connectable", bundle: .main)
        let controller = storyboard.instantiateInitialViewController() as! ConnectableViewController
        controller.ruuviTag = ruuviTag
        navigationController?.pushViewController(controller, animated: true)
    }
    
    private func openUnknown(device: BTUnknownDevice) {
        let storyboard = UIStoryboard(name: "Unknown", bundle: .main)
        let controller = storyboard.instantiateInitialViewController() as! UnknownViewController
        controller.device = device
        navigationController?.pushViewController(controller, animated: true)
    }
}

// MARK: - Observing & Reloading
extension MainViewController {
    private func startObserving() {
        scanToken = BTKit.foreground.scanner.scan(self) { (observer, device) in
            if let tag = device.ruuvi?.tag {
                observer.ruuviTagsSet.update(with: tag)
            }
        }
        unknownToken = BTKit.foreground.scanner.unknown(self, closure: { (observer, device) in
            observer.unknownSet.update(with: device)
        })
    }
    
    private func stopObserving() {
        scanToken?.invalidate()
        unknownToken?.invalidate()
    }
    
    private func startReloading() {
        reloadingTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true, block: { [weak self] _ in
            self?.updateRuuviTags()
            self?.updateUnknowns()
            self?.tableView.reloadData()
        })
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.updateRuuviTags()
            self?.updateUnknowns()
            self?.tableView.reloadData()
        }
    }
    
    private func stopReloading() {
        reloadingTimer?.invalidate()
        reloadingTimer = nil
    }
    
    private func updateRuuviTags() {
        ruuviTags = ruuviTagsSet.sorted(by: {
            if let rssi0 = $0.rssi, let rssi1 = $1.rssi {
                return rssi0 > rssi1
            } else {
                return true
            }
        })
    }
    
    private func updateUnknowns() {
        unknowns = unknownSet.sorted(by: { $0.rssi > $1.rssi })
    }
}
