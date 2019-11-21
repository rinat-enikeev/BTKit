import Foundation

public enum RuuviDevice {
    case tag(RuuviTag)
}

public extension RuuviDevice {
    var tag: RuuviTag? {
        if case let .tag(tag) = self {
            return tag
        } else {
            return nil
        }
    }
}

public enum RuuviTag {
    case v2(RuuviData2)
    case v3(RuuviData3)
    case v4(RuuviData4)
    case v5(RuuviData5)
    case h1(RuuviHeartbeat1)
}

public extension RuuviTag {
    
    var v2: RuuviData2? {
        if case let .v2(data) = self {
            return data
        } else {
            return nil
        }
    }
    
    var v3: RuuviData3? {
        if case let .v3(data) = self {
            return data
        } else {
            return nil
        }
    }
    
    var v4: RuuviData4? {
        if case let .v4(data) = self {
            return data
        } else {
            return nil
        }
    }
    
    var v5: RuuviData5? {
        if case let .v5(data) = self {
            return data
        } else {
            return nil
        }
    }
    
    var voltage: Double? {
        switch self {
        case .v2:
            return nil
        case .v3(let data):
            return data.voltage
        case .v4:
            return nil
        case .v5(let data):
            return data.voltage
        case .h1(let heartbeat):
            return heartbeat.voltage
        }
    }
    
    var accelerationX: Double? {
        switch self {
        case .v2:
            return nil
        case .v3(let data):
            return data.accelerationX
        case .v4:
            return nil
        case .v5(let data):
            return data.accelerationX
        case .h1(let heartbeat):
            return heartbeat.accelerationX
        }
    }
    
    var accelerationY: Double? {
        switch self {
        case .v2:
            return nil
        case .v3(let data):
            return data.accelerationY
        case .v4:
            return nil
        case .v5(let data):
            return data.accelerationY
        case .h1(let heartbeat):
            return heartbeat.accelerationY
        }
    }
    
    var accelerationZ: Double? {
        switch self {
        case .v2:
            return nil
        case .v3(let data):
            return data.accelerationZ
        case .v4:
            return nil
        case .v5(let data):
            return data.accelerationZ
        case .h1(let heartbeat):
            return heartbeat.accelerationZ
        }
    }
    
    var movementCounter: Int? {
        switch self {
        case .v2:
            return nil
        case .v3:
            return nil
        case .v4:
            return nil
        case .v5(let data):
            return data.movementCounter
        case .h1(let heartbeat):
            return heartbeat.movementCounter
        }
    }
    
    var measurementSequenceNumber: Int? {
        switch self {
        case .v2:
            return nil
        case .v3:
            return nil
        case .v4:
            return nil
        case .v5(let data):
            return data.measurementSequenceNumber
        case .h1(let heartbeat):
            return heartbeat.measurementSequenceNumber
        }
    }
    
    var txPower: Int? {
        switch self {
        case .v2:
            return nil
        case .v3:
            return nil
        case .v4:
            return nil
        case .v5(let data):
            return data.txPower
        case .h1(let heartbeat):
            return heartbeat.txPower
        }
    }
    
    var uuid: String {
        switch self {
        case .v2(let data):
            return data.uuid
        case .v3(let data):
            return data.uuid
        case .v4(let data):
            return data.uuid
        case .v5(let data):
            return data.uuid
        case .h1(let heartbeat):
            return heartbeat.uuid
        }
    }
    
    var rssi: Int? {
        switch self {
        case .v2(let data):
            return data.rssi
        case .v3(let data):
            return data.rssi
        case .v4(let data):
            return data.rssi
        case .v5(let data):
            return data.rssi
        case .h1:
            return nil
        }
    }
    
    var isConnectable: Bool {
        switch self {
        case .v2(let data):
            return data.isConnectable
        case .v3(let data):
            return data.isConnectable
        case .v4(let data):
            return data.isConnectable
        case .v5(let data):
            return data.isConnectable
        case .h1(let heartbeat):
            return heartbeat.isConnectable
        }
    }
    
    var version: Int {
        switch self {
        case .v2(let data):
            return data.version
        case .v3(let data):
            return data.version
        case .v4(let data):
            return data.version
        case .v5(let data):
            return data.version
        case .h1(let heartbeat):
            return heartbeat.version
        }
    }
    
    var humidity: Double? {
        switch self {
        case .v2(let data):
            return data.humidity
        case .v3(let data):
            return data.humidity
        case .v4(let data):
            return data.humidity
        case .v5(let data):
            return data.humidity
        case .h1(let heartbeat):
            return heartbeat.humidity
        }
    }
    
    var pressure: Double? {
        switch self {
        case .v2(let data):
            return data.pressure
        case .v3(let data):
            return data.pressure
        case .v4(let data):
            return data.pressure
        case .v5(let data):
            return data.pressure
        case .h1(let heartbeat):
            return heartbeat.pressure
        }
    }
    
    var celsius: Double? {
        switch self {
        case .v2(let data):
            return data.temperature
        case .v3(let data):
            return data.temperature
        case .v4(let data):
            return data.temperature
        case .v5(let data):
            return data.temperature
        case .h1(let heartbeat):
            return heartbeat.temperature
        }
    }
    
    var mac: String? {
        return v5?.mac
    }
    
    var fahrenheit: Double? {
        if let celsius = celsius {
            return (celsius * 9.0 / 5.0) + 32.0
        } else {
            return nil
        }
    }
    
    var kelvin: Double? {
        if let celsius = celsius {
            return celsius + 273.15
        } else {
            return nil
        }
    }
}

extension RuuviTag: Hashable {
    public func hash(into hasher: inout Hasher) {
        switch self {
        case .v2(let data):
            hasher.combine(data.uuid)
            hasher.combine("v2")
        case .v3(let data):
            hasher.combine(data.uuid)
            hasher.combine("v3")
        case .v4(let data):
            hasher.combine(data.uuid)
            hasher.combine("v4")
        case .v5(let data):
            hasher.combine(data.uuid)
            hasher.combine("v5")
        case .h1(let heartbeat):
            hasher.combine(heartbeat.uuid)
            hasher.combine("h1")
        }
    }
}

extension RuuviTag: Equatable {
    public static func ==(lhs: RuuviTag, rhs: RuuviTag) -> Bool {
        switch (lhs, rhs) {
        case let (.v2(l), .v2(r)): return l.uuid == r.uuid
        case let (.v3(l), .v3(r)): return l.uuid == r.uuid
        case let (.v4(l), .v4(r)): return l.uuid == r.uuid
        case let (.v5(l), .v5(r)): return l.uuid == r.uuid
        default: return false
        }
    }
}

public extension RuuviTag {
    var isConnected: Bool {
        return BTKit.background.scanner.isConnected(uuid: uuid)
    }
    
    
    @discardableResult
    func connect<T: AnyObject>(for observer: T, connected: @escaping (T, BTConnectResult) -> Void, heartbeat: @escaping (T, BTDevice) -> Void, disconnected: @escaping (T, BTDisconnectResult) -> Void) -> ObservationToken? {
        return connect(for: observer, options: nil, connected: connected, heartbeat: heartbeat, disconnected: disconnected)
    }
    
    @discardableResult
    func connect<T: AnyObject>(for observer: T, options: BTScannerOptionsInfo?, connected: @escaping (T, BTConnectResult) -> Void, heartbeat: @escaping (T, BTDevice) -> Void, disconnected: @escaping (T, BTDisconnectResult) -> Void) -> ObservationToken? {
        if !isConnectable {
            let info = BTKitParsedOptionsInfo(options)
            info.callbackQueue.execute {
                connected(observer, .failure(.logic(.notConnectable)))
            }
            return nil
        } else {
            return BTKit.background.connect(for: observer, uuid: uuid, options: options, connected: connected, heartbeat: heartbeat, disconnected: disconnected)
        }
    }
    
    @discardableResult
    func disconnect<T: AnyObject>(for observer: T, result: @escaping (T, BTDisconnectResult) -> Void) -> ObservationToken? {
        return disconnect(for: observer, options: nil, result: result)
    }
    
    @discardableResult
    func disconnect<T: AnyObject>(for observer: T, options: BTScannerOptionsInfo?, result: @escaping (T, BTDisconnectResult) -> Void) -> ObservationToken? {
        if !isConnectable {
            let info = BTKitParsedOptionsInfo(options)
            info.callbackQueue.execute {
                result(observer, .failure(.logic(.notConnectable)))
            }
            return nil
        } else {
            return BTKit.background.disconnect(for: observer, uuid: uuid, options: options, result: result)
        }
    }
    
    func celisus<T: AnyObject>(for observer: T, from date: Date, result: @escaping (T, Result<[RuuviTagEnvLog], BTError>) -> Void) {
        celisus(for: observer, from: date, options: nil, result: result)
    }
    
    func celisus<T: AnyObject>(for observer: T, from date: Date, options: BTScannerOptionsInfo?, result: @escaping (T, Result<[RuuviTagEnvLog], BTError>) -> Void) {
        if !isConnectable {
            let info = BTKitParsedOptionsInfo(options)
            info.callbackQueue.execute {
                result(observer, .failure(.logic(.notConnectable)))
            }
        } else {
            BTKit.background.services.ruuvi.nus.celisus(for: observer, uuid: uuid, from: date, result: result)
        }
    }
    
    func humidity<T: AnyObject>(for observer: T, from date: Date, result: @escaping (T, Result<[RuuviTagEnvLog], BTError>) -> Void) {
        humidity(for: observer, from: date, options: nil, result: result)
    }
    
    func humidity<T: AnyObject>(for observer: T, from date: Date, options: BTScannerOptionsInfo?, result: @escaping (T, Result<[RuuviTagEnvLog], BTError>) -> Void) {
        if !isConnectable {
            let info = BTKitParsedOptionsInfo(options)
            info.callbackQueue.execute {
                result(observer, .failure(.logic(.notConnectable)))
            }
        } else {
            BTKit.background.services.ruuvi.nus.humidity(for: observer, uuid: uuid, from: date, options: options, result: result)
        }
    }
    
    func pressure<T: AnyObject>(for observer: T, from date: Date, result: @escaping (T, Result<[RuuviTagEnvLog], BTError>) -> Void) {
        pressure(for: observer, from: date, options: nil, result: result)
    }
    
    func pressure<T: AnyObject>(for observer: T, from date: Date, options: BTScannerOptionsInfo?, result: @escaping (T, Result<[RuuviTagEnvLog], BTError>) -> Void) {
        if !isConnectable {
            let info = BTKitParsedOptionsInfo(options)
            info.callbackQueue.execute {
                result(observer, .failure(.logic(.notConnectable)))
            }
        } else {
            BTKit.background.services.ruuvi.nus.pressure(for: observer, uuid: uuid, from: date, options: options, result: result)
        }
    }
    
    func log<T: AnyObject>(for observer: T, from date: Date, result: @escaping (T, Result<[RuuviTagEnvLogFull], BTError>) -> Void) {
        log(for: observer, from: date, options: nil, result: result)
    }
    
    func log<T: AnyObject>(for observer: T, from date: Date, options: BTScannerOptionsInfo?, result: @escaping (T, Result<[RuuviTagEnvLogFull], BTError>) -> Void) {
        if !isConnectable {
            let info = BTKitParsedOptionsInfo(options)
            info.callbackQueue.execute {
                result(observer, .failure(.logic(.notConnectable)))
            }
        } else {
            BTKit.background.services.ruuvi.nus.log(for: observer, uuid: uuid, from: date, options: options, result: result)
        }
    }
}
