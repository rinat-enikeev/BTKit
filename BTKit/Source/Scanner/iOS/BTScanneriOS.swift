import CoreBluetooth

class BTScanneriOS: NSObject, BTScanner {
    private let queue = DispatchQueue(label: "CBCentralManager")
    private lazy var manager: CBCentralManager = {
        return CBCentralManager(delegate: self, queue: queue)
    }()
    private var observations = (
        state: [UUID : (BTScannerState) -> Void](),
        device: [UUID : (BTDevice) -> Void](),
        lost: [UUID: (BTDevice) -> Void]()
    )
    private var isReady = false { didSet { startStopIfNeeded() } }
    private var decoders: [BTDecoder]
    private var defaultOptions = BTScannerOptionsInfo.empty
    private var currentDefaultOptions: BTScannerOptionsInfo {
        return [] + defaultOptions
    }
    private var lastSeen = [BTDevice: Date]()
    private var lastSeenTimer: Timer?
    private var lostCheckInterval: TimeInterval = 1
    
    deinit {
        lastSeenTimer?.invalidate()
    }
    
    required init(decoders: [BTDecoder]) {
        self.decoders = decoders
        super.init()
        self.lastSeenTimer = Timer.scheduledTimer(withTimeInterval: lostCheckInterval, repeats: true, block: { [weak self] (timer) in
            guard let sSelf = self else { return }
            sSelf.observations.lost.values.forEach { (closure) in
                for device in sSelf.lastSeen.keys {
                    closure(device)
                }
            }
        })
    }
    
    private func startStopIfNeeded() {
        let shouldBeRunning = observations.state.count > 0 || observations.device.count > 0
        if shouldBeRunning && !manager.isScanning && isReady {
            manager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: NSNumber(value: true)])
        } else if !shouldBeRunning && manager.isScanning {
            manager.stopScan()
        }
    }
}

extension BTScanneriOS: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        isReady = central.state == CBManagerState.poweredOn
        if let state = BTScannerState(rawValue: central.state.rawValue) {
            observations.state.values.forEach { (closure) in
                closure(state)
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        guard RSSI.intValue != 127 else { return } 
        for decoder in decoders {
            if let device = decoder.decode(uuid: peripheral.identifier.uuidString, rssi: RSSI, advertisementData: advertisementData) {
                observations.device.values.forEach { (closure) in
                    closure(device)
                }
                lastSeen[device] = Date()
            }
        }
    }
    
    func centralManager( central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.discoverServices(nil)
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        if let error = error {
            print(error.localizedDescription)
        }
    }
}

extension BTScanneriOS {
    @discardableResult
    func lost<T: AnyObject>(_ observer: T, options: BTScannerOptionsInfo?, closure: @escaping (T, BTDevice) -> Void) -> ObservationToken {
        
        let options = currentDefaultOptions + (options ?? .empty)
        let info = BTKitParsedOptionsInfo(options)
        
        let id = UUID()
        
        observations.lost[id] = { [weak self, weak observer] device in
            guard let observer = observer else {
                self?.observations.lost.removeValue(forKey: id)
                return
            }
            
            if let lastSeen = self?.lastSeen[device] {
                let elapsed = Date().timeIntervalSince(lastSeen)
                if elapsed > info.lostDeviceDelay {
                    self?.lastSeen.removeValue(forKey: device)
                    info.callbackQueue.execute { [weak self, weak observer] in
                        guard let observer = observer else {
                            self?.observations.lost.removeValue(forKey: id)
                            return
                        }
                        closure(observer, device)
                    }
                }
            }
        }
        
        startStopIfNeeded()
        
        return ObservationToken { [weak self] in
            self?.observations.lost.removeValue(forKey: id)
            self?.startStopIfNeeded()
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
        observations.state[id] = { [weak self, weak observer] state in
            guard let observer = observer else {
                self?.observations.state.removeValue(forKey: id)
                return
            }
            info.callbackQueue.execute { [weak self, weak observer] in
                guard let observer = observer else {
                    self?.observations.state.removeValue(forKey: id)
                    return
                }
                closure(observer, state)

            }
        }
        
        startStopIfNeeded()
        
        return ObservationToken { [weak self] in
            self?.observations.state.removeValue(forKey: id)
            self?.startStopIfNeeded()
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
        observations.device[id] = { [weak self, weak observer] device in
            guard let observer = observer else {
                self?.observations.device.removeValue(forKey: id)
                return
            }
            info.callbackQueue.execute { [weak observer, weak self] in
                guard let observer = observer else {
                    self?.observations.device.removeValue(forKey: id)
                    return
                }
                closure(observer, device)
            }
        }
        
        startStopIfNeeded()
        
        return ObservationToken { [weak self] in
            self?.observations.device.removeValue(forKey: id)
            self?.startStopIfNeeded()
        }
    }
}
