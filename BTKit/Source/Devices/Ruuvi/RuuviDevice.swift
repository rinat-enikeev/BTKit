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
    
    func connect<T: AnyObject>(for observer: T, result: @escaping (T, BTConnectResult) -> Void) -> ObservationToken? {
        if !isConnectable {
            result(observer, .failure(.logic(.notConnectable)))
            return nil
        } else if isConnected {
            result(observer, .already)
            return nil
        } else {
            let connectToken = BTKit.scanner.connect(observer, uuid: uuid, connected: { (observer) in
                result(observer, .just)
            }) { (observer) in
                result(observer, .disconnected)
            }
            return connectToken
        }
    }
    
    func disconnect<T: AnyObject>(for observer: T, result: @escaping (T, BTDisconnectResult) -> Void) -> ObservationToken? {
        if !isConnected {
            result(observer, .already)
            return nil
        } else {
            return BTKit.scanner.disconnect(observer, uuid: uuid) { (observer) in
                result(observer, .just)
            }
        }
    }
    
    func celisus(for observer: AnyObject, from date: Date, result: @escaping (Result<[(Date,Double)], BTError>) -> Void) -> ObservationToken? {
        return serve(.temperature, for: observer, from: date, result: result)
    }
    
    func humidity(for observer: AnyObject, from date: Date, result: @escaping (Result<[(Date,Double)], BTError>) -> Void) -> ObservationToken? {
        return serve(.humidity, for: observer, from: date, result: result)
    }
    
    func pressure(for observer: AnyObject, from date: Date, result: @escaping (Result<[(Date,Double)], BTError>) -> Void) -> ObservationToken? {
        return serve(.pressure, for: observer, from: date, result: result)
    }
    
    func log(for observer: AnyObject, from date: Date, result: @escaping (Result<[RuuviTagLog], BTError>) -> Void) -> ObservationToken? {
        if !isConnectable {
            result(.failure(.logic(.notConnectable)))
            return nil
        } else if !isConnected {
            result(.failure(.logic(.notConnected)))
            return nil
        } else {
            var values = [RuuviTagLog]()
            var lastValue = RuuviTagLogClass()
            let service: BTRuuviNUSService = .all
            let serveToken = BTKit.scanner.serve(observer, for: uuid, .ruuvi(.uart(service)), request: { (observer, peripheral, rx, tx) in
                if let rx = rx {
                    peripheral?.writeValue(service.request(from: date), for: rx, type: .withResponse)
                } else {
                    result(.failure(.unexpected(.characteristicIsNil)))
                }
            }, response: { (observer, data) in
                if let data = data {
                    if service.isEndOfTransmissionFlag(data: data) {
                        result(.success(values))
                    } else if let row = service.responseRow(from: data) {
                        switch row.1 {
                        case .temperature:
                            lastValue.temperature = row.2
                        case .humidity:
                            lastValue.humidity = row.2
                        case .pressure:
                            lastValue.pressure = row.2
                        case .all:
                            break
                        }
                        if let t = lastValue.temperature,
                            let h = lastValue.humidity,
                            let p = lastValue.pressure {
                            let log = RuuviTagLog(date: row.0, temperature: t, humidity: h, pressure: p)
                            values.append(log)
                            lastValue = RuuviTagLogClass()
                        }
                    }
                } else {
                    result(.failure(.unexpected(.dataIsNil)))
                }
            }) { (observer, error) in
                result(.failure(error))
            }
            return serveToken
        }
    }
    
    private func serve(_ service: BTRuuviNUSService, for observer: AnyObject, from date: Date, result: @escaping (Result<[(Date,Double)], BTError>) -> Void) -> ObservationToken? {
        if !isConnectable {
            result(.failure(.logic(.notConnectable)))
            return nil
        } else if !isConnected {
            result(.failure(.logic(.notConnected)))
            return nil
        } else {
            var values = [(Date,Double)]()
            let serveToken = BTKit.scanner.serve(observer, for: uuid, .ruuvi(.uart(service)), request: { (observer, peripheral, rx, tx) in
                if let rx = rx {
                    peripheral?.writeValue(service.request(from: date), for: rx, type: .withResponse)
                } else {
                    result(.failure(.unexpected(.characteristicIsNil)))
                }
            }, response: { (observer, data) in
                if let data = data {
                    if service.isEndOfTransmissionFlag(data: data) {
                        result(.success(values))
                    } else if let row = service.response(from: data) {
                        values.append(row)
                    }
                } else {
                    result(.failure(.unexpected(.dataIsNil)))
                }
            }) { (observer, error) in
                result(.failure(error))
            }
            return serveToken
        }
    }
}

public struct RuuviTagLog {
    public var date: Date
    public var temperature: Double // in °C
    public var humidity: Double // relative in %
    public var pressure: Double // in hPa
}

private class RuuviTagLogClass {
    var date: Date?
    var temperature: Double? // in °C
    var humidity: Double? // relative in %
    var pressure: Double? // in hPa
}
