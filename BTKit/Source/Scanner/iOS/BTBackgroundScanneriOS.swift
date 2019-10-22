import Foundation
import CoreBluetooth
import AVFoundation
import UserNotifications

class BTBackgroundScanneriOS: NSObject, BTBackgroundScanner {
    
    var bluetoothState: BTScannerState = .unknown
    
    private let queue = DispatchQueue(label: "BTBackgroundScanneriOS", qos: .userInteractive)
    private lazy var manager: CBCentralManager = {
        return CBCentralManager(delegate: self, queue: queue, options: [CBCentralManagerOptionRestoreIdentifierKey: restoreId])
    }()
    private var service: BTService
    private var decoders: [BTDecoder]
    private var connectedPeripherals = Set<CBPeripheral>()
    private lazy var restoreId: String = {
        let bundleId = Bundle.main.bundleIdentifier ?? "io.btkit.BTKit"
        return bundleId + "." + "BTBackgroundScanneriOS." + service.uuid.uuidString
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
        service: [UUID: ServiceObservation]()
    )
    private var isReady = false { didSet { startIfNeeded() } }
    
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
        
        init(uuid: String, type: BTServiceType, request: ((CBPeripheral?, CBCharacteristic?, CBCharacteristic?) -> Void)?, response: ((Data?) -> Void)?, failure: ((BTError) -> Void)?) {
            self.uuid = uuid
            self.type = type
            self.request = request
            self.response = response
            self.failure = failure
        }
    }
    
    required init(service: BTService, decoders: [BTDecoder] = [RuuviDecoderiOS()]) {
        self.service = service
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
            manager.scanForPeripherals(withServices: [service.uuid], options: [CBCentralManagerOptionRestoreIdentifierKey: restoreId])
        }
    }
    
    private func shouldBeRunning() -> Bool {
        return observations.connect.count > 0
        || observations.disconnect.count > 0
        || observations.heartbeat.count > 0
        || observations.state.count > 0
        || observations.service.count > 0
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
        if let uart = service as? BTUARTService,
            uart.uuid == type.uuid,
            uart.isReady {
            info.callbackQueue.execute { [weak observer, weak self] in
                guard let observer = observer else {
                    self?.queue.async { [weak self] in
                        self?.observations.service.removeValue(forKey: id)
                        self?.stopIfNeeded()
                    }
                    return
                }
                let peripheral = self?.connectedPeripherals.first(where: { $0.identifier.uuidString == uuid })
                request?(observer, peripheral, uart.rx, uart.tx)
            }
        }
        
        return ObservationToken { [weak self] in
            self?.queue.async { [weak self] in
                self?.observations.service.removeValue(forKey: id)
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
        
        connectedPeripherals.forEach { (peripheral) in
            let hasService = peripheral.services?.contains(where: { $0.uuid == service.uuid }) ?? false
            if hasService {
                peripheral.discoverServices([service.uuid])
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
                    && !connectedPeripherals.contains(peripheral)
                    && peripheral.state != .connected {
                    connectedPeripherals.update(with: peripheral)
                    peripheral.delegate = self
                    manager.connect(peripheral)
                } else if !isConnectable {
                    connect.block(.logic(.notConnectable))
                }
            } )
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.discoverServices([service.uuid])
        observations.connect.values
            .filter({ $0.uuid == peripheral.identifier.uuidString })
            .forEach({ $0.block(nil) })
        
        let content = UNMutableNotificationContent()
        content.title = "Connected"
        content.body = peripheral.identifier.uuidString
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
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
            connectedPeripherals.update(with: peripheral)
            peripheral.delegate = self
            manager.connect(peripheral)
        } )

        
        let content = UNMutableNotificationContent()
        content.title = "Did Disconnect"
        content.body = peripheral.description
        let state = peripheral.state
        switch state {
        case .connected:
            content.subtitle = "Connected"
        case .connecting:
            content.subtitle = "Connecting"
        case .disconnected:
            content.subtitle = "Disconnected"
        case .disconnecting:
            content.subtitle = "Disconnecting"
        }
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
        
    }
      
    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        if invalidatedServices.contains(where: { $0.uuid == service.uuid }), connectedPeripherals.contains(peripheral) {
            manager.cancelPeripheralConnection(peripheral)
        }
    }
    
    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
        _ = manager
        
        if let peripherals = dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral] {
            peripherals.forEach({ $0.delegate = self })
            peripherals
                .filter({ $0.state == .disconnected || $0.state == .disconnecting })
                .forEach({
                    connectedPeripherals.update(with: $0)
                    manager.connect($0)
                })
            peripherals.filter({ $0.state == .connecting }).forEach( {
                connectedPeripherals.update(with: $0)
                manager.connect($0)
            })
            peripherals.filter({ $0.state == .connected }).forEach { (connectedPeripheral) in
                connectedPeripherals.update(with: connectedPeripheral)
                observations.connect.values
                    .filter({ $0.uuid == connectedPeripheral.identifier.uuidString })
                    .forEach({
                        $0.block(nil)
                    })
                connectedPeripheral.discoverServices([service.uuid])
            }
            let content = UNMutableNotificationContent()
            content.title = "WillRestoreState"
            content.body = peripherals.description
            
            if peripherals.count > 0 {
                let state = peripherals[0].state
                switch state {
                case .connected:
                    content.subtitle = "Connected"
                case .connecting:
                    content.subtitle = "Connecting"
                case .disconnected:
                    content.subtitle = "Disconnected"
                case .disconnecting:
                    content.subtitle = "Disconnecting"
                }
            }
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
            
        }
    }
}

extension BTBackgroundScanneriOS: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let discovered = peripheral.services else { return }
        for d in discovered {
            if d.uuid == service.uuid {
                if let uart = service as? BTUARTService {
                    peripheral.discoverCharacteristics([uart.txUUID, uart.rxUUID], for: d)
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        
        if let handler = self.service as? BTUARTService {
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
        } else {
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
        if let uart = self.service as? BTUARTService {
            uart.isReady = true
            observations.service.values
                .filter( {
                    $0.uuid == peripheral.identifier.uuidString &&
                    $0.type.uuid == uart.uuid
                } )
                .forEach( {
                    $0.request?(peripheral, uart.rx, uart.tx)
                } )
        }
    }
}
