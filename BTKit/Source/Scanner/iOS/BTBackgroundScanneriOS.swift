import Foundation
import CoreBluetooth
import AVFoundation

class BTBackgroundScanneriOS: NSObject, BTBackgroundScanner {
    
    var bluetoothState: BTScannerState = .unknown
    
    private let queue = DispatchQueue(label: "BTBackgroundScanneriOS", qos: .userInteractive)
    private lazy var manager: CBCentralManager = {
        return CBCentralManager(delegate: self, queue: queue, options: [CBCentralManagerOptionRestoreIdentifierKey: restoreId])
    }()
    private var services: [BTService]
    private var decoders: [BTDecoder]
    private var connectedPeripherals = Set<CBPeripheral>()
    private var connectingPeripherals = Set<CBPeripheral>()
    private lazy var restoreId: String = {
        let bundleId = Bundle.main.bundleIdentifier ?? "io.btkit.BTKit"
        return bundleId + "." + "BTBackgroundScanneriOS." + services.reduce("", { $0 + $1.uuid.uuidString })
    }()
    private var defaultOptions = BTScannerOptionsInfo.empty
    private var currentDefaultOptions: BTScannerOptionsInfo {
        return [] + defaultOptions
    }
    private var observations = (
        state: [UUID: (BTScannerState) -> Void](),
        connect: [UUID: ConnectObservation](),
        heartbeat: [UUID: HeartbeatObservation](),
        disconnect: [UUID: DisconnectObservation](),
        service: [UUID: ServiceObservation](),
        observe: [UUID: ObserveObservation]()
    )
    private var isReady = false { didSet { startIfNeeded() } }
    private var restorePeripherals = Set<CBPeripheral>()
    
    private class ConnectObservation {
        var block: (BTError?) -> Void
        var uuid: String = ""
        
        init(block: @escaping ((BTError?) -> Void), uuid: String) {
            self.block = block
            self.uuid = uuid
        }
    }
    
    private class HeartbeatObservation {
        var block: (BTDevice) -> Void
        var uuid: String = ""
        
        init(block: @escaping ((BTDevice) -> Void), uuid: String) {
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
        var madeRequest: Bool = false
        
        init(uuid: String, type: BTServiceType, request: ((CBPeripheral?, CBCharacteristic?, CBCharacteristic?) -> Void)?, response: ((Data?) -> Void)?, failure: ((BTError) -> Void)?) {
            self.uuid = uuid
            self.type = type
            self.request = request
            self.response = response
            self.failure = failure
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
    
    required init(services: [BTService], decoders: [BTDecoder]) {
        self.services = services
        self.decoders = decoders
        super.init()
    }
    
    func isConnected(uuid: String) -> Bool {
        return connectedPeripherals.contains(where: { $0.identifier.uuidString == uuid })
    }
    
    private func stopIfNeeded() {
        if !shouldBeRunning() && manager.isScanning {
            manager.stopScan()
        }
    }
    
    private func startIfNeeded() {
        if shouldBeRunning() && !manager.isScanning && isReady {
            manager.scanForPeripherals(withServices: services.map({ $0.uuid }), options: [CBCentralManagerOptionRestoreIdentifierKey: restoreId])
        }
    }
    
    private func shouldBeRunning() -> Bool {
        return observations.connect.count > 0
        || observations.disconnect.count > 0
        || observations.heartbeat.count > 0
        || observations.state.count > 0
        || observations.service.count > 0
        || observations.observe.count > 0
    }
    
}

extension BTBackgroundScanneriOS {
    
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
    func connect<T: AnyObject>(_ observer: T, uuid: String,
                               options: BTScannerOptionsInfo?,
                               connected: @escaping (T, BTError?) -> Void,
                               heartbeat: @escaping (T, BTDevice) -> Void,
                               disconnected: @escaping (T, BTError?) -> Void) -> ObservationToken {
        let options = currentDefaultOptions + (options ?? .empty)
        let info = BTKitParsedOptionsInfo(options)
        
        let id = UUID()
        
        queue.async { [weak self] in
            self?.observations.connect[id] = ConnectObservation(block: { [weak self, weak observer] error in
                guard let observer = observer else {
                    self?.observations.connect.removeValue(forKey: id)
                    self?.stopIfNeeded()
                    return
                }
                info.callbackQueue.execute { [weak observer, weak self] in
                    guard let observer = observer else {
                        self?.queue.async { [weak self] in
                            self?.observations.connect.removeValue(forKey: id)
                            self?.stopIfNeeded()
                        }
                        return
                    }
                    connected(observer, error)
                }
            }, uuid: uuid)
            
            self?.observations.disconnect[id] = DisconnectObservation(block: { [weak self, weak observer] error in
                guard let observer = observer else {
                    self?.observations.disconnect.removeValue(forKey: id)
                    self?.stopIfNeeded()
                    return
                }
                info.callbackQueue.execute { [weak observer, weak self] in
                    guard let observer = observer else {
                        self?.queue.async { [weak self] in
                            self?.observations.disconnect.removeValue(forKey: id)
                            self?.stopIfNeeded()
                        }
                        return
                    }
                    disconnected(observer, error)
                }
            }, uuid: uuid)
            
            self?.observations.heartbeat[id] = HeartbeatObservation(block: { [weak self, weak observer] (device) in
                guard let observer = observer else {
                    self?.observations.heartbeat.removeValue(forKey: id)
                    self?.stopIfNeeded()
                    return
                }
                info.callbackQueue.execute { [weak observer, weak self] in
                    guard let observer = observer else {
                        self?.queue.async { [weak self] in
                            self?.observations.heartbeat.removeValue(forKey: id)
                            self?.stopIfNeeded()
                        }
                        return
                    }
                    heartbeat(observer, device)
                }
            }, uuid: uuid)
            
            self?.startIfNeeded()
        }
        
        if bluetoothState == .poweredOn,
            let uuidObject = UUID(uuidString: uuid) {
            let peripherals = manager.retrievePeripherals(withIdentifiers: [uuidObject])
            peripherals.filter( { $0.identifier.uuidString == uuid } ).forEach { (peripheral) in
                if peripheral.state != .connected {
                    connectingPeripherals.update(with: peripheral)
                    peripheral.delegate = self
                    manager.connect(peripheral)
                }
            }
        }
        
        return ObservationToken { [weak self] in
            self?.queue.async { [weak self] in
                self?.observations.connect.removeValue(forKey: id)
                self?.observations.disconnect.removeValue(forKey: id)
                self?.observations.heartbeat.removeValue(forKey: id)
                self?.stopIfNeeded()
            }
        }
    }
    
    @discardableResult
    func disconnect<T: AnyObject>(_ observer: T, uuid: String, options: BTScannerOptionsInfo?, disconnected: @escaping (T, BTError?) -> Void) -> ObservationToken {
        
        let options = currentDefaultOptions + (options ?? .empty)
        let info = BTKitParsedOptionsInfo(options)
        
        let id = UUID()
        
        queue.async { [weak self] in
            self?.observations.disconnect[id] = DisconnectObservation(block: { [weak self, weak observer] error in
                guard let observer = observer else {
                    self?.observations.disconnect.removeValue(forKey: id)
                    self?.stopIfNeeded()
                    return
                }
                info.callbackQueue.execute { [weak observer, weak self] in
                    guard let observer = observer else {
                        self?.queue.async { [weak self] in
                            self?.observations.disconnect.removeValue(forKey: id)
                            self?.stopIfNeeded()
                        }
                        return
                    }
                    disconnected(observer, error)
                }
            }, uuid: uuid)
            
            self?.startIfNeeded()
        }
        
        queue.async { [weak self] in
            if let connectedClients = self?.observations.connect.values.filter({ $0.uuid == uuid }).count {
                if connectedClients == 0 {
                    self?.connectingPeripherals
                        .filter( { $0.identifier.uuidString == uuid } )
                        .forEach({ (peripheral) in
                            if peripheral.state != .disconnected {
                                self?.manager.cancelPeripheralConnection(peripheral)
                            }
                        })
                    self?.connectedPeripherals.filter( { $0.identifier.uuidString == uuid } )
                    .forEach({ (peripheral) in
                        if peripheral.state != .disconnected {
                            self?.manager.cancelPeripheralConnection(peripheral)
                        }
                    })
                } else {
                    info.callbackQueue.execute { [weak observer, weak self] in
                        guard let observer = observer else {
                            self?.queue.async { [weak self] in
                                self?.observations.disconnect.removeValue(forKey: id)
                                self?.stopIfNeeded()
                            }
                            return
                        }
                        disconnected(observer, .logic(.connectedByOthers))
                    }
                }
            }
        }
        
        return ObservationToken { [weak self] in
            self?.queue.async { [weak self] in
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
                    self?.stopIfNeeded()
                    return
                }
                info.callbackQueue.execute { [weak observer, weak self] in
                    guard let observer = observer else {
                        self?.queue.async { [weak self] in
                            self?.observations.service.removeValue(forKey: id)
                            self?.stopIfNeeded()
                        }
                        return
                    }
                    request?(observer, peripheral, rx, tx)
                }
            }, response: { [weak self, weak observer] (data) in
                guard let observer = observer else {
                    self?.observations.service.removeValue(forKey: id)
                    self?.stopIfNeeded()
                    return
                }
                info.callbackQueue.execute { [weak observer, weak self] in
                    guard let observer = observer else {
                        self?.queue.async { [weak self] in
                            self?.observations.service.removeValue(forKey: id)
                            self?.stopIfNeeded()
                        }
                        return
                    }
                    response?(observer, data)
                }
            }, failure: { [weak self, weak observer] (error) in
                guard let observer = observer else {
                    self?.observations.service.removeValue(forKey: id)
                    self?.stopIfNeeded()
                    return
                }
                info.callbackQueue.execute { [weak observer, weak self] in
                    guard let observer = observer else {
                        self?.queue.async { [weak self] in
                            self?.observations.service.removeValue(forKey: id)
                            self?.stopIfNeeded()
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
                        self?.stopIfNeeded()
                    }
                    return
                }
                let peripheral = self?.connectedPeripherals.first(where: { $0.identifier.uuidString == uuid })
                self?.queue.async { [weak self] in
                    self?.observations.service.values.filter({ $0.uuid == uuid }).forEach({ $0.madeRequest = true })
                }
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
}

extension BTBackgroundScanneriOS: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        isReady = central.state == CBManagerState.poweredOn
        bluetoothState = BTScannerState(rawValue: central.state.rawValue) ?? .unknown
        if let state = BTScannerState(rawValue: central.state.rawValue) {
            observations.state.values.forEach { (closure) in
                closure(state)
            }
        }
        if isReady {
            restorePeripherals.forEach { (peripheral) in
                peripheral.delegate = self
                switch peripheral.state {
                case .connected:
                    connectedPeripherals.update(with: peripheral)
                    observations.connect.values
                        .filter({ $0.uuid == peripheral.identifier.uuidString })
                        .forEach({
                            $0.block(nil)
                        })
                case .connecting:
                    connectingPeripherals.update(with: peripheral)
                    manager.connect(peripheral)
                default:
                    observations.connect.values
                        .filter({ $0.uuid == peripheral.identifier.uuidString })
                        .forEach( { connect in
                            if !connectingPeripherals.contains(peripheral) {
                                connectingPeripherals.update(with: peripheral)
                                manager.connect(peripheral)
                            }
                        } )   
                }
            }
            restorePeripherals.removeAll()
            
            connectedPeripherals.forEach { (peripheral) in
                peripheral.discoverServices(services.map({ $0.uuid }))
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        guard RSSI.intValue != 127 else { return }
        let uuid = peripheral.identifier.uuidString
        let isConnectable = (advertisementData[CBAdvertisementDataIsConnectable] as? NSNumber)?.boolValue ?? false
        observations.connect.values
            .filter({ $0.uuid == uuid })
            .forEach( { connect in
                if isConnectable
                    && !connectingPeripherals.contains(peripheral)
                    && !connectedPeripherals.contains(peripheral)
                    && peripheral.state != .connected {
                    connectingPeripherals.update(with: peripheral)
                    peripheral.delegate = self
                    manager.connect(peripheral)
                } else if !isConnectable {
                    connect.block(.logic(.notConnectable))
                }
            } )
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        connectingPeripherals.remove(peripheral)
        connectedPeripherals.update(with: peripheral)
        peripheral.discoverServices(services.map({ $0.uuid }))
        observations.connect.values
            .filter({ $0.uuid == peripheral.identifier.uuidString })
            .forEach({ $0.block(nil) })
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        connectingPeripherals.remove(peripheral)
        connectedPeripherals.remove(peripheral)
        // but still notify
        observations.disconnect.values
            .filter({ $0.uuid == peripheral.identifier.uuidString })
            .forEach({
                $0.block(nil)
            })
        // keep connection if still needs to
        observations.connect.values
        .filter({ $0.uuid == peripheral.identifier.uuidString })
        .forEach( { connect in
            connectingPeripherals.update(with: peripheral)
            peripheral.delegate = self
            manager.connect(peripheral)
        } )
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        connectingPeripherals.remove(peripheral)
        if let error = error {
            observations.connect.values
                .filter({ $0.uuid == peripheral.identifier.uuidString })
                .forEach({
                    $0.block(.connect(error))
                })
        }
    }
    
    func centralManager(_ central: CBCentralManager, connectionEventDidOccur event: CBConnectionEvent, for peripheral: CBPeripheral) {
        print(event)
    }
      
    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        
        if invalidatedServices
            .filter({ services.map( { $0.uuid } ).contains($0.uuid) })
            .count > 0,
            connectedPeripherals.contains(peripheral) {
            manager.cancelPeripheralConnection(peripheral)
        }
    }
    
    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
        if let peripherals = dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral] {
            peripherals.forEach({ $0.delegate = self })
            restorePeripherals.formUnion(peripherals)
        }
        _ = manager
    }
}

extension BTBackgroundScanneriOS: CBPeripheralDelegate {
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
        
        var heartbeatDevice: BTDevice?
        for decoder in decoders {
            if let device = decoder.decodeHeartbeat(uuid: peripheral.identifier.uuidString, data: characteristic.value) {
                heartbeatDevice = device
                break
            }
        }
        
        if let heartbeatDevice = heartbeatDevice {
            observations.heartbeat.values.filter( {
                $0.uuid == peripheral.identifier.uuidString
            } )
            .forEach( {
                $0.block(heartbeatDevice)
            } )
            observations.observe.values
            .filter({
                $0.uuid == peripheral.identifier.uuidString
            })
            .forEach( {
                $0.block(heartbeatDevice)
            } )
        } else {
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
                    if !$0.madeRequest {
                        $0.request?(peripheral, service.rx, service.tx)
                        $0.madeRequest = true
                    }
                } )
        }
    }
}
