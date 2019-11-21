import CoreBluetooth
#if canImport(UIKit)
import UIKit
#endif

class BTScanneriOS: NSObject, BTScanner {
    
    var bluetoothState: BTScannerState = .unknown
    
    private class LostObservation {
        var block: (BTDevice) -> Void
        var lostDeviceDelay: TimeInterval
        
        init(block: @escaping ((BTDevice) -> Void), lostDeviceDelay: TimeInterval) {
            self.block = block
            self.lostDeviceDelay = lostDeviceDelay
        }
    }
    
    private class ObserveObservation {
        var block: (BTDevice) -> Void
        var uuid: String = ""
        
        init(block: @escaping ((BTDevice) -> Void), uuid: String) {
            self.block = block
            self.uuid = uuid
        }
    }

    private let queue = DispatchQueue(label: "BTScanneriOS", qos: .userInteractive)
    private lazy var manager: CBCentralManager = {
        return CBCentralManager(delegate: self, queue: queue)
    }()
    private var observations = (
        state: [UUID: (BTScannerState) -> Void](),
        device: [UUID: (BTDevice) -> Void](),
        lost: [UUID: LostObservation](),
        observe: [UUID: ObserveObservation](),
        unknown: [UUID: (BTUnknownDevice) -> Void]()
    )
    private var isReady = false { didSet { startIfNeeded() } }
    private var decoders: [BTDecoder]
    private var defaultOptions = BTScannerOptionsInfo.empty
    private var currentDefaultOptions: BTScannerOptionsInfo {
        return [] + defaultOptions
    }
    private var lastSeen = [BTDevice: Date]()
    private var lostTimer: DispatchSourceTimer?
    private var restartTimer: DispatchSourceTimer?
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        lostTimer?.cancel()
        restartTimer?.cancel()
    }
    
    required init(decoders: [BTDecoder]) {
        self.decoders = decoders
        super.init()
#if os(iOS) || os(watchOS) || os(tvOS)
        NotificationCenter.default.addObserver(self, selector: #selector(self.willResignActiveNotification(_:)), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.didBecomeActiveNotification(_:)), name: UIApplication.didBecomeActiveNotification, object: nil)
#endif
        queue.async { [weak self] in
            self?.setupRestartTimer()
        }
    }
    
    @objc func willResignActiveNotification(_ notification: Notification)  {
        queue.async { [weak self] in
            self?.manager.stopScan()
        }
    }
    
    @objc func didBecomeActiveNotification(_ notification: Notification)  {
        queue.async { [weak self] in
            self?.startIfNeeded()
        }
    }
    
    func setupRestartTimer() {
        restartTimer = DispatchSource.makeTimerSource(queue: queue)
        restartTimer?.schedule(deadline: .now() + 60, repeating: .seconds(60))
        restartTimer?.setEventHandler { [weak self] in
            self?.manager.stopScan()
            self?.startIfNeeded()
        }
        restartTimer?.activate()
    }
    
    func startLostDevicesTimer() {
        lostTimer = DispatchSource.makeTimerSource(queue: queue)
        lostTimer?.schedule(deadline: .now(), repeating: .seconds(1))
        lostTimer?.setEventHandler { [weak self] in
            self?.notifyLostDevices()
        }
        lostTimer?.activate()
    }
    
    func stopLostDevicesTimer() {
        lostTimer?.cancel()
        lostTimer = nil
    }
    
    private func notifyLostDevices() {
        observations.lost.values.forEach { (observation) in
            var lostDevices = [BTDevice]()
            for (device,seen) in lastSeen {
                let elapsed = Date().timeIntervalSince(seen)
                if elapsed > observation.lostDeviceDelay {
                    lostDevices.append(device)
                }
            }
            for lostDevice in lostDevices {
                lastSeen.removeValue(forKey: lostDevice)
                observation.block(lostDevice)
            }
        }
    }
    
    private func startIfNeeded() {
        if shouldBeRunning() && !manager.isScanning && isReady {
            manager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: NSNumber(value: true)])
        }
        
        let shouldObserveLostDevices = observations.lost.count > 0
        if shouldObserveLostDevices && lostTimer == nil {
            startLostDevicesTimer()
        }
    }
    
    private func stopIfNeeded() {
        if !shouldBeRunning() && manager.isScanning {
            manager.stopScan()
        }
        
        let shouldObserveLostDevices = observations.lost.count > 0
        if !shouldObserveLostDevices && lostTimer != nil {
            stopLostDevicesTimer()
        }
    }
    
    private func shouldBeRunning() -> Bool {
        return observations.state.count > 0
        || observations.device.count > 0
        || observations.lost.count > 0
        || observations.observe.count > 0
    }
}

// MARK: - CBCentralManagerDelegate
extension BTScanneriOS: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        isReady = central.state == CBManagerState.poweredOn
        bluetoothState = BTScannerState(rawValue: central.state.rawValue) ?? .unknown
        if let state = BTScannerState(rawValue: central.state.rawValue) {
            observations.state.values.forEach { (closure) in
                closure(state)
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        guard RSSI.intValue != 127 else { return }
        let uuid = peripheral.identifier.uuidString
        let isConnectable = (advertisementData[CBAdvertisementDataIsConnectable] as? NSNumber)?.boolValue ?? false
        for decoder in decoders {
            if let device = decoder.decodeAdvertisement(uuid: uuid, rssi: RSSI, advertisementData: advertisementData) {
                observations.device.values.forEach { (closure) in
                    closure(device)
                }
                lastSeen[device] = Date()
                observations.observe.values
                    .filter({ $0.uuid == device.uuid })
                    .forEach( { $0.block(device) } )
                return
            }
        }
        
        let name = advertisementData[CBAdvertisementDataLocalNameKey] as? String
        let unknownDevice = BTUnknownDevice(uuid: uuid, rssi: RSSI.intValue, isConnectable: isConnectable, name: name)
        observations.unknown.values.forEach { (closure) in
            closure(unknownDevice)
        }
    }
}

extension BTScanneriOS {
    
    @discardableResult
    func lost<T: AnyObject>(_ observer: T, options: BTScannerOptionsInfo?, closure: @escaping (T, BTDevice) -> Void) -> ObservationToken {
        
        let options = currentDefaultOptions + (options ?? .empty)
        let info = BTKitParsedOptionsInfo(options)
        
        let id = UUID()
        
        queue.async { [weak self] in
            
            self?.observations.lost[id] = LostObservation(block: { [weak self, weak observer] (device) in
                guard let observer = observer else {
                    self?.observations.lost.removeValue(forKey: id)
                    self?.stopIfNeeded()
                    return
                }
                
                info.callbackQueue.execute { [weak self, weak observer] in
                    guard let observer = observer else {
                        self?.queue.async { [weak self] in
                            self?.observations.lost.removeValue(forKey: id)
                            self?.stopIfNeeded()
                        }
                        return
                    }

                    closure(observer, device)
                }
            }, lostDeviceDelay: info.lostDeviceDelay)
            
            self?.startIfNeeded()
        }
        
        return ObservationToken { [weak self] in
            self?.queue.async { [weak self] in
                self?.observations.lost.removeValue(forKey: id)
                self?.stopIfNeeded()
            }
        }
    }
    
    
    @discardableResult
    func state<T: AnyObject>(
        _ observer: T,
        options: BTScannerOptionsInfo? = nil,
        closure: @escaping (T, BTScannerState) -> Void
        ) -> ObservationToken {
        
        let options = currentDefaultOptions + (options ?? .empty)
        let info = BTKitParsedOptionsInfo(options)
        
        let id = UUID()
        
        queue.async { [weak self] in
            self?.observations.state[id] = { [weak self, weak observer] state in
                guard let observer = observer else {
                    self?.observations.state.removeValue(forKey: id)
                    self?.stopIfNeeded()
                    return
                }
                info.callbackQueue.execute { [weak self, weak observer] in
                    guard let observer = observer else {
                        self?.queue.async { [weak self] in
                            self?.observations.state.removeValue(forKey: id)
                            self?.stopIfNeeded()
                        }
                        return
                    }
                    closure(observer, state)
                }
            }
            
            self?.startIfNeeded()
        }
        
        return ObservationToken { [weak self] in
            self?.queue.async { [weak self] in
                self?.observations.state.removeValue(forKey: id)
                self?.stopIfNeeded()
            }
        }
    }
    
    @discardableResult
    func scan<T: AnyObject>(
        _ observer: T,
        options: BTScannerOptionsInfo? = nil,
        closure: @escaping (T, BTDevice) -> Void
        ) -> ObservationToken {
        
        let options = currentDefaultOptions + (options ?? .empty)
        let info = BTKitParsedOptionsInfo(options)
        
        let id = UUID()
        var demoTimer: Timer?
        
        if info.demoCount > 0 {
            var uuids = [String]()
            for _ in 0..<info.demoCount {
                uuids.append(UUID().uuidString)
            }
            demoTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { (timer) in
                info.callbackQueue.execute { [weak observer] in
                    if let observer = observer {
                        for uuid in uuids {
                            closure(observer, DemoFactory.shared.build(for: uuid))
                        }
                    } else {
                        DispatchQueue.main.async {
                            demoTimer?.invalidate()
                        }
                    }
                }
            }
        } else {
            queue.async { [weak self] in
                self?.observations.device[id] = { [weak self, weak observer] device in
                    guard let observer = observer else {
                        self?.observations.device.removeValue(forKey: id)
                        self?.stopIfNeeded()
                        return
                    }
                    info.callbackQueue.execute { [weak observer, weak self] in
                        guard let observer = observer else {
                            self?.queue.async { [weak self] in
                                self?.observations.device.removeValue(forKey: id)
                                self?.stopIfNeeded()
                            }
                            return
                        }
                        closure(observer, device)
                    }
                }
                
                self?.startIfNeeded()
            }
        }
        
        return ObservationToken { [weak self] in
            DispatchQueue.main.async {
                demoTimer?.invalidate()
            }
            self?.queue.async { [weak self] in
                self?.observations.device.removeValue(forKey: id)
                self?.stopIfNeeded()
            }
        }
    }
    
    @discardableResult
    func observe<T: AnyObject>(_ observer: T, uuid: String, options: BTScannerOptionsInfo?, closure: @escaping (T, BTDevice) -> Void) -> ObservationToken {
        let options = currentDefaultOptions + (options ?? .empty)
        let info = BTKitParsedOptionsInfo(options)
        
        let id = UUID()
        
        queue.async { [weak self] in
            self?.observations.observe[id] = ObserveObservation(block: { [weak self, weak observer] device in
                guard let observer = observer else {
                    self?.observations.observe.removeValue(forKey: id)
                    self?.stopIfNeeded()
                    return
                }
                info.callbackQueue.execute { [weak observer, weak self] in
                    guard let observer = observer else {
                        self?.queue.async { [weak self] in
                            self?.observations.observe.removeValue(forKey: id)
                            self?.stopIfNeeded()
                        }
                        return
                    }
                    closure(observer, device)
                }
            }, uuid: uuid)
            self?.startIfNeeded()
        }
        
        return ObservationToken { [weak self] in
            self?.queue.async { [weak self] in
                self?.observations.observe.removeValue(forKey: id)
                self?.stopIfNeeded()
            }
        }
    }
    
    @discardableResult
    func unknown<T: AnyObject>(
        _ observer: T,
        options: BTScannerOptionsInfo? = nil,
        closure: @escaping (T, BTUnknownDevice) -> Void
        ) -> ObservationToken {
        
        let options = currentDefaultOptions + (options ?? .empty)
        let info = BTKitParsedOptionsInfo(options)
        
        let id = UUID()
        
        queue.async { [weak self] in
            self?.observations.unknown[id] = { [weak self, weak observer] device in
                guard let observer = observer else {
                    self?.observations.unknown.removeValue(forKey: id)
                    self?.stopIfNeeded()
                    return
                }
                info.callbackQueue.execute { [weak observer, weak self] in
                    guard let observer = observer else {
                        self?.queue.async { [weak self] in
                            self?.observations.unknown.removeValue(forKey: id)
                            self?.stopIfNeeded()
                        }
                        return
                    }
                    closure(observer, device)
                }
            }
            
            self?.startIfNeeded()
        }
        
        return ObservationToken { [weak self] in
            self?.queue.async { [weak self] in
                self?.observations.unknown.removeValue(forKey: id)
                self?.stopIfNeeded()
            }
        }
    }
}
