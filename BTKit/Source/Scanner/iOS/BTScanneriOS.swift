import CoreBluetooth

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
    
    private class ConnectObservation {
        var block: (BTError?) -> Void
        var uuid: String = ""
        
        init(block: @escaping ((BTError?) -> Void), uuid: String) {
            self.block = block
            self.uuid = uuid
        }
    }
    
    private class DisconnectObservation {
        var block: (BTError?) -> Void
        var uuid: String = ""
        
        init(block: @escaping ((BTError?) -> Void), uuid: String) {
            self.block = block
            self.uuid = uuid
        }
    }
    
    private class ServiceObservation {
        var request: ((CBPeripheral?, CBCharacteristic?, CBCharacteristic?) -> Void)?
        var response: ((Data?) -> Void)?
        var failure: ((BTError) -> Void)?
        var uuid: String = ""
        var type: BTServiceType
        
        init(uuid: String, type: BTServiceType, request: ((CBPeripheral?, CBCharacteristic?, CBCharacteristic?) -> Void)?, response: ((Data?) -> Void)?, failure: ((BTError) -> Void)?) {
            self.uuid = uuid
            self.type = type
            self.request = request
            self.response = response
            self.failure = failure
        }
    }
    
    private var connectedPeripherals = Set<CBPeripheral>()
    private let queue = DispatchQueue(label: "CBCentralManager", qos: .userInteractive)
    private lazy var manager: CBCentralManager = {
        return CBCentralManager(delegate: self, queue: queue)
    }()
    private var observations = (
        state: [UUID : (BTScannerState) -> Void](),
        device: [UUID : (BTDevice) -> Void](),
        lost: [UUID: LostObservation](),
        observe: [UUID: ObserveObservation](),
        connect: [UUID: ConnectObservation](),
        disconnect: [UUID: DisconnectObservation](),
        service: [UUID: ServiceObservation]()
    )
    private var isReady = false { didSet { startIfNeeded() } }
    private var decoders: [BTDecoder]
    private var services: [BTService]
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
    
    required init(decoders: [BTDecoder], services: [BTService]) {
        self.decoders = decoders
        self.services = services
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(self.willResignActiveNotification(_:)), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.didBecomeActiveNotification(_:)), name: UIApplication.didBecomeActiveNotification, object: nil)
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
        let shouldBeRunning = observations.state.count > 0
            || observations.device.count > 0
            || observations.lost.count > 0
            || observations.observe.count > 0
            || observations.connect.count > 0
            || observations.service.count > 0
        
        if shouldBeRunning && !manager.isScanning && isReady {
            manager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: NSNumber(value: true)])
        }
        
        let shouldObserveLostDevices = observations.lost.count > 0
        if shouldObserveLostDevices && lostTimer == nil {
            startLostDevicesTimer()
        }
    }
    
    private func stopIfNeeded() {
        let shouldBeRunning = observations.state.count > 0
            || observations.device.count > 0
            || observations.lost.count > 0
            || observations.observe.count > 0
        
        if !shouldBeRunning && manager.isScanning {
            manager.stopScan()
        }
        
        let shouldObserveLostDevices = observations.lost.count > 0
        if !shouldObserveLostDevices && lostTimer != nil {
            stopLostDevicesTimer()
        }
    }
}

extension BTScanneriOS: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let discovered = peripheral.services else { return }
        for d in discovered {
            if let service = services.first(where: { $0.uuid == d.uuid }) {
                if let uart = service as? BTUARTService {
                    peripheral.discoverCharacteristics([uart.txUUID, uart.rxUUID], for: d)
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        
        if let handler = services.first(where: { $0.uuid == service.uuid }) as? BTUARTService {
            handler.tx = characteristics.first(where: { $0.uuid == handler.txUUID })
            handler.rx = characteristics.first(where: { $0.uuid == handler.rxUUID })
            if let tx = handler.tx, tx.properties.contains(.notify) {
                peripheral.setNotifyValue(true, for: tx)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?) {
        print(descriptor)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Error?) {
        print(descriptor)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        services.compactMap { (service) -> BTUARTService? in
            let uart = service as? BTUARTService
            let isService = characteristic.service.uuid == service.uuid
            let isCharacteristic = uart?.tx?.uuid == characteristic.uuid
            return isService && isCharacteristic ? uart : nil
        }.forEach { (service) in
            observations.service.values
                .filter( {
                    $0.uuid == peripheral.identifier.uuidString &&
                    $0.type.uuid == service.uuid
                } )
                .forEach( {
                    $0.response?(characteristic.value)
                } )
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        services.compactMap { (service) -> BTUARTService? in
            let uart = service as? BTUARTService
            let isService = characteristic.service.uuid == service.uuid
            let isCharacteristic = uart?.tx?.uuid == characteristic.uuid
            return isService && isCharacteristic ? uart : nil
        }.forEach { (service) in
            service.isReady = true
            observations.service.values
                .filter( {
                    $0.uuid == peripheral.identifier.uuidString &&
                    $0.type.uuid == service.uuid
                } )
                .forEach( {
                    $0.request?(peripheral, service.rx, service.tx)
                } )
        }
    }
}

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
        for decoder in decoders {
            if let device = decoder.decode(uuid: peripheral.identifier.uuidString, rssi: RSSI, advertisementData: advertisementData) {
                observations.device.values.forEach { (closure) in
                    closure(device)
                }
                lastSeen[device] = Date()
                observations.observe.values
                    .filter({ $0.uuid == device.uuid })
                    .forEach( { $0.block(device) } )
                observations.connect.values
                    .filter({ $0.uuid == device.uuid })
                    .forEach( { connect in
                        let isConnectable = (advertisementData[CBAdvertisementDataIsConnectable] as? NSNumber)?.boolValue ?? false
                        if isConnectable {
                            if !connectedPeripherals.contains(peripheral) {
                                connectedPeripherals.insert(peripheral)
                                peripheral.delegate = self
                                manager.connect(peripheral)
                            }
                        } else {
                            connect.block(.logic(.notConnectable))
                        }
                    } )
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.discoverServices(nil)
        observations.connect.values
            .filter({ $0.uuid == peripheral.identifier.uuidString })
            .forEach({ $0.block(nil) })
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        observations.disconnect.values
            .filter({ $0.uuid == peripheral.identifier.uuidString })
            .forEach({ $0.block(nil) })
        connectedPeripherals.remove(peripheral)
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        if let error = error {
            print(error.localizedDescription) // TODO: pass error to connect caller
        }
    }
}

extension BTScanneriOS {
    
    func isConnected(uuid: String) -> Bool {
        return connectedPeripherals.contains(where: { $0.identifier.uuidString == uuid })
    }
    
    @discardableResult
    func lost<T: AnyObject>(_ observer: T, options: BTScannerOptionsInfo?, closure: @escaping (T, BTDevice) -> Void) -> ObservationToken {
        
        let options = currentDefaultOptions + (options ?? .empty)
        let info = BTKitParsedOptionsInfo(options)
        
        let id = UUID()
        
        queue.async { [weak self] in
            
            self?.observations.lost[id] = LostObservation(block: { [weak self, weak observer] (device) in
                guard let observer = observer else {
                    self?.observations.lost.removeValue(forKey: id)
                    return
                }
                
                info.callbackQueue.execute { [weak self, weak observer] in
                    guard let observer = observer else {
                        self?.queue.async { [weak self] in
                            self?.observations.lost.removeValue(forKey: id)
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
                    return
                }
                info.callbackQueue.execute { [weak self, weak observer] in
                    guard let observer = observer else {
                        self?.queue.async { [weak self] in
                            self?.observations.state.removeValue(forKey: id)
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
                        return
                    }
                    info.callbackQueue.execute { [weak observer, weak self] in
                        guard let observer = observer else {
                            self?.queue.async { [weak self] in
                                self?.observations.device.removeValue(forKey: id)
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
                    return
                }
                info.callbackQueue.execute { [weak observer, weak self] in
                    guard let observer = observer else {
                        self?.queue.async { [weak self] in
                            self?.observations.observe.removeValue(forKey: id)
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
    func connect<T: AnyObject>(_ observer: T, uuid: String, options: BTScannerOptionsInfo?, connected: @escaping (T, BTError?) -> Void, disconnected: @escaping (T, BTError?) -> Void) -> ObservationToken {
        let options = currentDefaultOptions + (options ?? .empty)
        let info = BTKitParsedOptionsInfo(options)
        
        let id = UUID()
        
        queue.async { [weak self] in
            self?.observations.connect[id] = ConnectObservation(block: { [weak self, weak observer] error in
                guard let observer = observer else {
                    self?.observations.connect.removeValue(forKey: id)
                    return
                }
                info.callbackQueue.execute { [weak observer, weak self] in
                    guard let observer = observer else {
                        self?.queue.async { [weak self] in
                            self?.observations.connect.removeValue(forKey: id)
                        }
                        return
                    }
                    connected(observer, error)
                }
            }, uuid: uuid)
            
            self?.observations.disconnect[id] = DisconnectObservation(block: { [weak self, weak observer] error in
                guard let observer = observer else {
                    self?.observations.disconnect.removeValue(forKey: id)
                    return
                }
                info.callbackQueue.execute { [weak observer, weak self] in
                    guard let observer = observer else {
                        self?.queue.async { [weak self] in
                            self?.observations.disconnect.removeValue(forKey: id)
                        }
                        return
                    }
                    disconnected(observer, error)
                }
            }, uuid: uuid)
            self?.startIfNeeded()
        }
        
        return ObservationToken { [weak self] in
            self?.queue.async { [weak self] in
                self?.observations.connect.removeValue(forKey: id)
                self?.observations.disconnect.removeValue(forKey: id)
                self?.stopIfNeeded()
            }
        }
    }
    
    @discardableResult
    func serve<T: AnyObject>(_ observer: T, for uuid: String, _ type: BTServiceType, options: BTScannerOptionsInfo?, request: ((T, CBPeripheral?, CBCharacteristic?, CBCharacteristic?) -> Void)?, response: ((T, Data?) -> Void)?, failure: ((T, BTError) -> Void)?) -> ObservationToken {
        
        let options = currentDefaultOptions + (options ?? .empty)
        let info = BTKitParsedOptionsInfo(options)
        
        let id = UUID()
        
        queue.async { [weak self] in
            self?.observations.service[id] = ServiceObservation(uuid: uuid, type: type, request: { [weak self, weak observer] (peripheral, rx, tx) in
                guard let observer = observer else {
                    self?.observations.service.removeValue(forKey: id)
                    return
                }
                info.callbackQueue.execute { [weak observer, weak self] in
                    guard let observer = observer else {
                        self?.queue.async { [weak self] in
                            self?.observations.service.removeValue(forKey: id)
                        }
                        return
                    }
                    request?(observer, peripheral, rx, tx)
                }
            }, response: { [weak self, weak observer] (data) in
                guard let observer = observer else {
                    self?.observations.service.removeValue(forKey: id)
                    return
                }
                info.callbackQueue.execute { [weak observer, weak self] in
                    guard let observer = observer else {
                        self?.queue.async { [weak self] in
                            self?.observations.service.removeValue(forKey: id)
                        }
                        return
                    }
                    response?(observer, data)
                }
            }, failure: { [weak self, weak observer] (error) in
                guard let observer = observer else {
                    self?.observations.service.removeValue(forKey: id)
                    return
                }
                info.callbackQueue.execute { [weak observer, weak self] in
                    guard let observer = observer else {
                        self?.queue.async { [weak self] in
                            self?.observations.service.removeValue(forKey: id)
                        }
                        return
                    }
                    failure?(observer, error)
                }
            })
            
            self?.startIfNeeded()
        }
        
        // call if service is ready
        services.compactMap { (service) -> BTUARTService? in
            guard let uart = service as? BTUARTService else { return nil }
            return uart.uuid == type.uuid && uart.isReady ? uart : nil
        }.forEach { (service) in
            info.callbackQueue.execute { [weak observer, weak self] in
                guard let observer = observer else {
                    self?.queue.async { [weak self] in
                        self?.observations.service.removeValue(forKey: id)
                    }
                    return
                }
                let peripheral = self?.connectedPeripherals.first(where: { $0.identifier.uuidString == uuid })
                request?(observer, peripheral, service.rx, service.tx)
            }
        }
        
        return ObservationToken { [weak self] in
            self?.queue.async { [weak self] in
                self?.observations.service.removeValue(forKey: id)
                self?.stopIfNeeded()
            }
        }
    }
    
    func disconnect<T: AnyObject>(_ observer: T, uuid: String, options: BTScannerOptionsInfo?, disconnected: @escaping (T, BTError?) -> Void) -> ObservationToken {
        
        let options = currentDefaultOptions + (options ?? .empty)
        let info = BTKitParsedOptionsInfo(options)
        
        let id = UUID()
        
        queue.async { [weak self] in
            self?.observations.disconnect[id] = DisconnectObservation(block: { [weak self, weak observer] error in
                guard let observer = observer else {
                    self?.observations.disconnect.removeValue(forKey: id)
                    return
                }
                info.callbackQueue.execute { [weak observer, weak self] in
                    guard let observer = observer else {
                        self?.queue.async { [weak self] in
                            self?.observations.disconnect.removeValue(forKey: id)
                        }
                        return
                    }
                    disconnected(observer, error)
                }
            }, uuid: uuid)
            
            self?.startIfNeeded()
        }
        
        queue.async { [weak self] in
            if let connectedClients = self?.observations.connect.values.filter({ $0.uuid == uuid }).count, connectedClients == 0 {
                self?.connectedPeripherals
                    .filter( { $0.identifier.uuidString == uuid } )
                    .forEach({ (peripheral) in
                        if peripheral.state != .disconnected {
                            self?.manager.cancelPeripheralConnection(peripheral)
                        }
                    })
            }
        }
        
        return ObservationToken { [weak self] in
            self?.queue.async { [weak self] in
                self?.observations.disconnect.removeValue(forKey: id)
                self?.stopIfNeeded()
            }
        }
    }
}
