import CoreBluetooth

class BTScanneriOS: NSObject, BTScanner {
    private let queue = DispatchQueue(label: "CBCentralManager")
    private lazy var manager: CBCentralManager = {
        return CBCentralManager(delegate: self, queue: queue)
    }()
    private var observations = (
        state: [UUID : (BTScannerState) -> Void](),
        device: [UUID : (BTDevice) -> Void]()
    )
    private var isReady = false { didSet { startStopIfNeeded() } }
    private var decoders: [BTDecoder]
    
    required init(decoders: [BTDecoder]) {
        self.decoders = decoders
        super.init()
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
    func observeState<T: AnyObject>(
        _ observer: T,
        closure: @escaping (T, BTScannerState) -> Void
        ) -> ObservationToken {
        let id = UUID()
        observations.state[id] = { [weak self, weak observer] state in
            // If the observer has been deallocated, we can
            // automatically remove the observation closure.
            guard let observer = observer else {
                self?.observations.state.removeValue(forKey: id)
                return
            }
            closure(observer, state)
        }
        
        startStopIfNeeded()
        
        return ObservationToken { [weak self] in
            self?.observations.state.removeValue(forKey: id)
            self?.startStopIfNeeded()
        }
    }
    
    @discardableResult
    func observeDevice<T: AnyObject>(
        _ observer: T,
        closure: @escaping (T, BTDevice) -> Void
        ) -> ObservationToken {
        let id = UUID()
        observations.device[id] = { [weak self, weak observer] device in
            // If the observer has been deallocated, we can
            // automatically remove the observation closure.
            guard let observer = observer else {
                self?.observations.device.removeValue(forKey: id)
                return
            }
            closure(observer, device)
        }
        
        startStopIfNeeded()
        
        return ObservationToken { [weak self] in
            self?.observations.device.removeValue(forKey: id)
            self?.startStopIfNeeded()
        }
    }
}
