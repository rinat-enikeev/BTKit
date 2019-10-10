import Foundation
import CoreBluetooth

public enum BTServiceType {
    case ruuvi(BTRuuviServiceType)
    
    var uuid: CBUUID {
        switch self {
        case .ruuvi(let type):
            switch type {
            case .uart(let service):
                return service.uuid
            }
        }
    }
}

public enum BTRuuviNUSService {
    case temperature // in °C
    case humidity // relative in %
    case pressure // in hPa
    case all
    
    var uuid: CBUUID {
        return CBUUID(string: "6E400001-B5A3-F393-E0A9-E50E24DCCA9E")
    }
    
    var flag: UInt8 {
        switch self {
        case .temperature:
            return 0x30
        case .humidity:
            return 0x31
        case .pressure:
            return 0x32
        case .all:
            return 0x3A
        }
    }
    
    var multiplier: Double {
        switch self {
        case .temperature:
            return 0.01
        case .humidity:
            return 0.01
        case .pressure:
            return 0.01
        case .all:
            return 0.01
        }
    }
    
    func request(from date: Date) -> Data {
        let nowTI = Date().timeIntervalSince1970
        var now = UInt32(nowTI)
        now = UInt32(bigEndian: now)
        var fromTI = date.timeIntervalSince1970
        fromTI = fromTI < 0 ? 0 : fromTI
        var from = UInt32(fromTI)
        from = UInt32(bigEndian: from)
        let nowData = withUnsafeBytes(of: now) { Data($0) }
        let fromData = withUnsafeBytes(of: from) { Data($0) }
        var data = Data()
        data.append(flag)
        data.append(0x30)
        data.append(0x11)
        data.append(nowData)
        data.append(fromData)
        return data
    }
    
    func responseRow(from data: Data) -> (Date,BTRuuviNUSService,Double)? {
        guard data.count == 11 else { return nil }
        var service: BTRuuviNUSService
        switch data[1] {
        case BTRuuviNUSService.temperature.flag:
            service = .temperature
        case BTRuuviNUSService.humidity.flag:
            service = .humidity
        case BTRuuviNUSService.pressure.flag:
            service = .pressure
        default:
            return nil
        }
        guard let value = response(from: data, for: service) else { return nil }
        return (value.0, service, value.1)
    }
    
    func response(from data: Data) -> (Date,Double)? {
        return response(from: data, for: self)
    }
    
    func response(from data: Data, for service: BTRuuviNUSService) -> (Date,Double)? {
        guard data.count == 11 else { return nil }
        guard data[1] == service.flag else { return nil }
        let timestampData = data[3...6]
        var timestamp: UInt32 = 0
        let timestampBytesCopied = withUnsafeMutableBytes(of: &timestamp, { timestampData.copyBytes(to: $0)} )
        timestamp = UInt32(bigEndian: timestamp)
        assert(timestampBytesCopied == MemoryLayout.size(ofValue: timestamp))
        
        let valueData = data[7...10]
        var value: Int32 = 0
        let valueBytesCopied = withUnsafeMutableBytes(of: &value, { valueData.copyBytes(to: $0) })
        assert(valueBytesCopied == MemoryLayout.size(ofValue: value))
        
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        value = Int32(bigEndian: value)
        return (date, Double(value) * service.multiplier)
    }
    
    func isEndOfTransmissionFlag(data: Data) -> Bool {
        guard data.count == 11 else { return false }
        let payload = data[3...10]
        var value: UInt64 = 0
        let bytesCopied = withUnsafeMutableBytes(of: &value, { payload.copyBytes(to: $0)} )
        assert(bytesCopied == MemoryLayout.size(ofValue: value))
        return value == UInt64.max
    }
}

public enum BTRuuviServiceType {
    case uart(BTRuuviNUSService)
}

public protocol BTService: class {
    var uuid: CBUUID { get }
}

public protocol BTUARTService: BTService {
    var txUUID: CBUUID { get }
    var rxUUID: CBUUID { get }
    var tx: CBCharacteristic? { get set }
    var rx: CBCharacteristic? { get set }
    var isReady: Bool { get set }
}

public struct BTKitService {
    public let ruuvi = BTKitRuuviService()
}

public struct BTKitRuuviService {
    public let uart = BTKitRuuviUARTService()
}

public struct BTKitRuuviUARTService {
    public let nus = BTKitRuuviNUSService()
}

public struct BTKitRuuviNUSService {
    
    @discardableResult
    public func celisus<T: AnyObject>(for observer: T, uuid: String, from date: Date, result: @escaping (T, Result<[RuuviTagEnvLog], BTError>) -> Void) -> ObservationToken? {
        return celisus(for: observer, uuid: uuid, from: date, options: nil, result: result)
    }
    
    @discardableResult
    public func celisus<T: AnyObject>(for observer: T, uuid: String, from date: Date, options: BTScannerOptionsInfo?, result: @escaping (T, Result<[RuuviTagEnvLog], BTError>) -> Void) -> ObservationToken? {
        return serve(.temperature, for: observer, uuid: uuid, from: date, options: options, result: result)
    }
    
    @discardableResult
    public func humidity<T: AnyObject>(for observer: T, uuid: String, from date: Date, result: @escaping (T, Result<[RuuviTagEnvLog], BTError>) -> Void) -> ObservationToken? {
        return humidity(for: observer, uuid: uuid, from: date, options: nil, result: result)
    }
    
    @discardableResult
    public func humidity<T: AnyObject>(for observer: T, uuid: String, from date: Date, options: BTScannerOptionsInfo?, result: @escaping (T, Result<[RuuviTagEnvLog], BTError>) -> Void) -> ObservationToken? {
        return serve(.humidity, for: observer, uuid: uuid, from: date, options: options, result: result)
    }
    
    @discardableResult
    public func pressure<T: AnyObject>(for observer: T, uuid: String, from date: Date, result: @escaping (T, Result<[RuuviTagEnvLog], BTError>) -> Void) -> ObservationToken? {
            return pressure(for: observer, uuid: uuid, from: date, options: nil, result: result)
    }
    
    @discardableResult
    public func pressure<T: AnyObject>(for observer: T, uuid: String, from date: Date, options: BTScannerOptionsInfo?, result: @escaping (T, Result<[RuuviTagEnvLog], BTError>) -> Void) -> ObservationToken? {
        return serve(.pressure, for: observer, uuid: uuid, from: date, options: options, result: result)
    }
    
    @discardableResult
    public func log<T: AnyObject>(for observer: T, uuid: String, from date: Date, result: @escaping (T, Result<[RuuviTagEnvLogFull], BTError>) -> Void) -> ObservationToken? {
        return log(for: observer, uuid: uuid, from: date, options: nil, result: result)
    }
    
    @discardableResult
    public func log<T: AnyObject>(for observer: T, uuid: String, from date: Date, options: BTScannerOptionsInfo?, result: @escaping (T, Result<[RuuviTagEnvLogFull], BTError>) -> Void) -> ObservationToken? {
        let info = BTKitParsedOptionsInfo(options)
        if !BTKit.scanner.isConnected(uuid: uuid) {
            info.callbackQueue.execute {
                result(observer, .failure(.logic(.notConnected)))
            }
            return nil
        } else {
            var values = [RuuviTagEnvLogFull]()
            var lastValue = RuuviTagEnvLogFullClass()
            let service: BTRuuviNUSService = .all
            let serveToken = BTKit.scanner.serve(observer, for: uuid, .ruuvi(.uart(service)), options: options, request: { (observer, peripheral, rx, tx) in
                if let rx = rx {
                    peripheral?.writeValue(service.request(from: date), for: rx, type: .withResponse)
                } else {
                    info.callbackQueue.execute {
                        result(observer, .failure(.unexpected(.characteristicIsNil)))
                    }
                }
            }, response: { (observer, data) in
                if let data = data {
                    if service.isEndOfTransmissionFlag(data: data) {
                        info.callbackQueue.execute {
                            result(observer, .success(values))
                        }
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
                            let log = RuuviTagEnvLogFull(date: row.0, temperature: t, humidity: h, pressure: p)
                            values.append(log)
                            lastValue = RuuviTagEnvLogFullClass()
                        }
                    }
                } else {
                    info.callbackQueue.execute {
                        result(observer, .failure(.unexpected(.dataIsNil)))
                    }
                }
            }) { (observer, error) in
                info.callbackQueue.execute {
                    result(observer, .failure(error))
                }
            }
            return serveToken
        }
    }
    
    private func serve<T: AnyObject>(_ service: BTRuuviNUSService, for observer: T, uuid: String, from date: Date, options: BTScannerOptionsInfo?, result: @escaping (T, Result<[RuuviTagEnvLog], BTError>) -> Void) -> ObservationToken? {
        let info = BTKitParsedOptionsInfo(options)
        if !BTKit.scanner.isConnected(uuid: uuid) {
            info.callbackQueue.execute {
                result(observer, .failure(.logic(.notConnected)))
            }
            return nil
        } else {
            var values = [RuuviTagEnvLog]()
            let serveToken = BTKit.scanner.serve(observer, for: uuid, .ruuvi(.uart(service)), options: options, request: { (observer, peripheral, rx, tx) in
                if let rx = rx {
                    peripheral?.writeValue(service.request(from: date), for: rx, type: .withResponse)
                } else {
                    info.callbackQueue.execute {
                        result(observer, .failure(.unexpected(.characteristicIsNil)))
                    }
                }
            }, response: { (observer, data) in
                if let data = data {
                    if service.isEndOfTransmissionFlag(data: data) {
                        info.callbackQueue.execute {
                            result(observer, .success(values))
                        }
                    } else if let row = service.response(from: data) {
                        values.append(RuuviTagEnvLog(type: service, date: row.0, value: row.1))
                    }
                } else {
                    info.callbackQueue.execute {
                        result(observer, .failure(.unexpected(.dataIsNil)))
                    }
                }
            }) { (observer, error) in
                info.callbackQueue.execute {
                    result(observer, .failure(error))
                }
            }
            return serveToken
        }
    }
}

public struct RuuviTagEnvLog {
    public var type: BTRuuviNUSService
    public var date: Date
    public var value: Double
}

public struct RuuviTagEnvLogFull {
    public var date: Date
    public var temperature: Double // in °C
    public var humidity: Double // relative in %
    public var pressure: Double // in hPa
}

class RuuviTagEnvLogFullClass {
    var date: Date?
    var temperature: Double? // in °C
    var humidity: Double? // relative in %
    var pressure: Double? // in hPa
}

