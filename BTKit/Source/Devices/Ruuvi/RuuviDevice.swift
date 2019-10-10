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
        }
    }
    
    var movementCounter: Int? {
        return v5?.movementCounter
    }
    
    var measurementSequenceNumber: Int? {
        return v5?.measurementSequenceNumber
    }
    
    var txPower: Int? {
        return v5?.txPower
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
        }
    }
    
    var rssi: Int {
        switch self {
        case .v2(let data):
            return data.rssi
        case .v3(let data):
            return data.rssi
        case .v4(let data):
            return data.rssi
        case .v5(let data):
            return data.rssi
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
        return BTKit.scanner.isConnected(uuid: uuid)
    }
    
    
    @discardableResult
    func connect<T: AnyObject>(for observer: T, result: @escaping (T, BTConnectResult) -> Void) -> ObservationToken? {
        return connect(for: observer, options: nil, result: result)
    }
    
    @discardableResult
    func connect<T: AnyObject>(for observer: T, options: BTScannerOptionsInfo?, result: @escaping (T, BTConnectResult) -> Void) -> ObservationToken? {
        if !isConnectable {
            let info = BTKitParsedOptionsInfo(options)
            info.callbackQueue.execute {
                result(observer, .failure(.logic(.notConnectable)))
            }
            return nil
        } else {
            return BTKit.connection.establish(for: observer, uuid: uuid, options: options, result: result)
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
            return BTKit.connection.drop(for: observer, uuid: uuid, result: result)
        }
    }
    
    @discardableResult
    func celisus<T: AnyObject>(for observer: T, from date: Date, result: @escaping (T, Result<[RuuviTagEnvLog], BTError>) -> Void) -> ObservationToken? {
        return celisus(for: observer, from: date, options: nil, result: result)
    }
    
    @discardableResult
    func celisus<T: AnyObject>(for observer: T, from date: Date, options: BTScannerOptionsInfo?, result: @escaping (T, Result<[RuuviTagEnvLog], BTError>) -> Void) -> ObservationToken? {
        if !isConnectable {
            let info = BTKitParsedOptionsInfo(options)
            info.callbackQueue.execute {
                result(observer, .failure(.logic(.notConnectable)))
            }
            return nil
        } else {
            return BTKit.service.ruuvi.uart.nus.celisus(for: observer, uuid: uuid, from: date, result: result)
        }
    }
    
    @discardableResult
    func humidity<T: AnyObject>(for observer: T, from date: Date, result: @escaping (T, Result<[RuuviTagEnvLog], BTError>) -> Void) -> ObservationToken? {
        return humidity(for: observer, from: date, options: nil, result: result)
    }
    
    @discardableResult
    func humidity<T: AnyObject>(for observer: T, from date: Date, options: BTScannerOptionsInfo?, result: @escaping (T, Result<[RuuviTagEnvLog], BTError>) -> Void) -> ObservationToken? {
        if !isConnectable {
            let info = BTKitParsedOptionsInfo(options)
            info.callbackQueue.execute {
                result(observer, .failure(.logic(.notConnectable)))
            }
            return nil
        } else {
            return BTKit.service.ruuvi.uart.nus.humidity(for: observer, uuid: uuid, from: date, options: options, result: result)
        }
    }
    
    @discardableResult
    func pressure<T: AnyObject>(for observer: T, from date: Date, result: @escaping (T, Result<[RuuviTagEnvLog], BTError>) -> Void) -> ObservationToken? {
        return pressure(for: observer, from: date, options: nil, result: result)
    }
    
    @discardableResult
    func pressure<T: AnyObject>(for observer: T, from date: Date, options: BTScannerOptionsInfo?, result: @escaping (T, Result<[RuuviTagEnvLog], BTError>) -> Void) -> ObservationToken? {
        if !isConnectable {
            let info = BTKitParsedOptionsInfo(options)
            info.callbackQueue.execute {
                result(observer, .failure(.logic(.notConnectable)))
            }
            return nil
        } else {
            return BTKit.service.ruuvi.uart.nus.pressure(for: observer, uuid: uuid, from: date, options: options, result: result)
        }
    }
    
    @discardableResult
    func log<T: AnyObject>(for observer: T, from date: Date, result: @escaping (T, Result<[RuuviTagEnvLogFull], BTError>) -> Void) -> ObservationToken? {
        return log(for: observer, from: date, options: nil, result: result)
    }
    
    @discardableResult
    func log<T: AnyObject>(for observer: T, from date: Date, options: BTScannerOptionsInfo?, result: @escaping (T, Result<[RuuviTagEnvLogFull], BTError>) -> Void) -> ObservationToken? {
        if !isConnectable {
            let info = BTKitParsedOptionsInfo(options)
            info.callbackQueue.execute {
                result(observer, .failure(.logic(.notConnectable)))
            }
            return nil
        } else {
            return BTKit.service.ruuvi.uart.nus.log(for: observer, uuid: uuid, from: date, options: options, result: result)
        }
    }
}
