import Foundation
import CoreBluetooth

public enum BTServiceProgress {
    case connecting
    case serving
    case reading(Int)
    case disconnecting
    case success
    case failure(BTError)
}

public enum Progressable {
    case points(Int)
    case logs([RuuviTagEnvLogFull])
}

public enum BTServiceType {
    case ledger(LedgerServiceType)
    case ruuvi(BTRuuviServiceType)
    case gatt(BTGATTServiceType)

    var uuid: CBUUID {
        switch self {
        case .ledger(let type):
            return type.uuid
        case .ruuvi(let type):
            switch type {
            case .nus(let service):
                return service.uuid
            }
        case .gatt(let type):
            switch type {
            case .deviceInformation(let service):
                return service.uuid
            }
        }
    }
}

public struct LedgerSignMessageResult {
    public var v: UInt8
    public var r: Data
    public var s: Data
}

public struct LedgerAddressResult {
    public var publicKey: String
    public var address: String
}

public enum LedgerServiceType {
    case address
    case messageHash

    var uuid: CBUUID {
        switch self {
        case .address:
            return CBUUID(string: "13d63400-2c97-0004-0000-4c6564676572")
        case .messageHash:
            return CBUUID(string: "13d63400-2c97-0004-0000-4c6564676572")
        }
    }

    public func decodeSignMessage(data: Data) -> LedgerSignMessageResult? {
        guard data.count >= 65 else { return nil }
        return LedgerSignMessageResult(
            v: data[0],
            r: Data(data[1 ..< 1 + 32]),
            s: Data(data[1 + 32 ..< 1 + 32 + 32])
        )
    }

    public func requestSignMessageHash(path: String, messageHash: String) -> Data? {
        guard let adpu = signMessageAPDU(path: path, messageHash: messageHash) else { return nil }
        var result = Data()

        // Tag Id
        result.append(0x05)
        // Index
        result.append(0x00)
        result.append(0x00)

        // apdu length
        guard let count = UInt16(exactly: adpu.count) else { return nil }
        withUnsafeBytes(of: count.bigEndian) { result.append(contentsOf: $0) }

        result.append(adpu)
        return result
    }

    func signMessageAPDU(path: String, messageHash: String) -> Data? {
        var result = Data()
        result.append(0xe0)
        result.append(0x08)
        result.append(0x00)
        result.append(0x00)
        guard let paths = splitPath(path: path) else { return nil }
        var pathsData = Data()
        paths.forEach { withUnsafeBytes(of: $0.bigEndian) { pathsData.append(contentsOf: $0) } }
        var data = Data()
        data.append(UInt8(paths.count))
        data.append(pathsData)

        guard let messageData = messageHash.data(using: .hexadecimal) else { return nil }
        let array = withUnsafeBytes(of: Int32(messageData.count).bigEndian, Array.init)
        array.forEach { data.append($0) }
        data.append(messageData)

        result.append(UInt8(data.count))
        result.append(data)

        guard result.count <= 150 else { return nil }
        return result
    }

    public func decodeAddress(data: Data) -> LedgerAddressResult? {
        let offset = 6

        guard data.count > offset - 1 else { return nil }
        let publicKeyLength: Int = Int(data[offset - 1])

        guard data.count > offset + publicKeyLength - 1 else { return nil }
        let publicKey = Data(data[offset...offset + publicKeyLength - 1]).hexEncodedString()

        guard data.count > offset + publicKeyLength else { return nil }
        let addressLength = Int(data[offset + publicKeyLength])

        guard data.count > offset + publicKeyLength + 1 + addressLength else { return nil }
        let addressData = Data(data[offset + publicKeyLength + 1...offset + publicKeyLength + 1 + addressLength])
        guard let addressWithout0x = String(data: addressData, encoding: .ascii) else { return nil }
        let address = "0x" + addressWithout0x
        return LedgerAddressResult(publicKey: publicKey, address: address)
    }

    public func requestAddress(path: String, verify: Bool) -> Data? {
        var result = Data()
        // TagId
        result.append(0x05)
        // chunk index
        result.append(0x00)
        result.append(0x00)

        guard let apdu = addressAPDU(path: path, verify: verify) else { return nil }
        guard let request = addressRequest(verify: verify, apdu: apdu) else { return nil }
        guard let count = UInt16(exactly: request.count) else { return nil }
        withUnsafeBytes(of: count.bigEndian) { result.append(contentsOf: $0) }

        result.append(request)
        return result
    }

    func addressRequest(verify: Bool, apdu: Data) -> Data? {
        var result = Data()
        // cla
        result.append(0xe0)
        // ins
        result.append(0x02)
        // verify
        result.append(verify ? 0x01 : 0x00)
        // chainCode
        result.append(0x00) // chain code not supported yet

        guard let count = UInt8(exactly: apdu.count) else { return nil }
        withUnsafeBytes(of: count.bigEndian) { result.append(contentsOf: $0) }

        result.append(apdu)

        return result
    }

    func addressAPDU(path: String, verify: Bool) -> Data? {
        var data = Data()
        guard let paths = splitPath(path: path) else { return nil }
        guard let count = UInt8(exactly: paths.count) else { return nil }
        data.append(count)
        paths.forEach {
            withUnsafeBytes(of: $0.bigEndian) { data.append(contentsOf: $0) }
        }
        return data
    }

    func splitPath(path: String) -> [UInt32]? {
        var result = [UInt32]()
        let components = path.components(separatedBy: "/")
        components.forEach { element in
            guard var number = UInt32(element.replacingOccurrences(of: "'", with: "")) else { return }
            if element.count > 1 && element.last == "'" {
                number += 0x80000000
            }
            result.append(number)
        }
        guard result.count == components.count else { return nil }
        return result
      }
}

public enum BTGATTDeviceInformationService {
    case firmwareRevision(BTGATTDeviceInformationFirmwareRevisionService)

    var uuid: CBUUID {
        switch self {
        case .firmwareRevision(let value):
            return value.uuid
        }
    }

    var characteristic: CBUUID {
        switch self {
        case .firmwareRevision(let value):
            return value.characteristic
        }
    }
}

public enum BTGATTDeviceInformationFirmwareRevisionService {
    case standard

    var uuid: CBUUID {
        switch self {
        case .standard:
            return CBUUID(string: "180a")
        }
    }

    var characteristic: CBUUID {
        switch self {
        case .standard:
            return CBUUID(string: "2a26")
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
    case nus(BTRuuviNUSService)
}

public enum BTGATTServiceType {
    case deviceInformation(BTGATTDeviceInformationService)

    var uuid: CBUUID {
        switch self {
        case .deviceInformation(let value):
            return value.uuid
        }
    }

    var characteristic: CBUUID {
        switch self {
        case .deviceInformation(let value):
            return value.characteristic
        }
    }
}

public protocol BTService: AnyObject {
    var uuid: CBUUID { get }
}

public protocol BTUARTService: BTService {
    var txUUID: CBUUID { get }
    var rxUUID: CBUUID { get }
}

public struct BTServices {
    public let ledger = BTKitLedgerUARTService()
    public let ruuvi = BTRuuviServices()
    public let gatt = BTGATTService()
}

public struct BTRuuviServices {
    public let nus = BTKitRuuviNUSService()
}

public struct BTGATTService {
    public func firmwareRevision<T:AnyObject>(for observer: T, uuid: String, options: BTScannerOptionsInfo? = nil, progress: ((BTServiceProgress) -> Void)? = nil, result: @escaping (T, Result<String, BTError>) -> Void) {
        var connectToken: ObservationToken?
        progress?(.connecting)
        connectToken = BTKit.background.connect(for: observer, uuid: uuid, options: options, connected: { (observer, connectResult) in
            connectToken?.invalidate()
            switch connectResult {
            case .already:
                var serveToken: ObservationToken?
                progress?(.serving)
                serveToken = self.serveFirmware(observer, uuid, options) { observer, serveResult in
                    serveToken?.invalidate()
                    var disconnectToken: ObservationToken?
                    progress?(.disconnecting)
                    disconnectToken = BTKit.background.disconnect(for: observer, uuid: uuid, options: options) { (observer, disconnectResult) in
                        disconnectToken?.invalidate()
                        switch disconnectResult {
                        case .already:
                            progress?(.success)
                            result(observer, serveResult)
                        case .just:
                            progress?(.success)
                            result(observer, serveResult)
                        case .stillConnected:
                            progress?(.success)
                            result(observer, serveResult)
                        case .bluetoothWasPoweredOff:
                            progress?(.success)
                            result(observer, serveResult)
                        case .failure(let error):
                            progress?(.failure(error))
                            result(observer, .failure(error))
                        }
                    }
                }
            case .just:
                var serveToken: ObservationToken?
                progress?(.serving)
                serveToken = self.serveFirmware(observer, uuid, options) { observer, serveResult in
                    serveToken?.invalidate()
                    var disconnectToken: ObservationToken?
                    progress?(.disconnecting)
                    disconnectToken = BTKit.background.disconnect(for: observer, uuid: uuid, options: options) { (observer, disconnectResult) in
                        disconnectToken?.invalidate()
                        switch disconnectResult {
                        case .already:
                            progress?(.success)
                            result(observer, serveResult)
                        case .just:
                            progress?(.success)
                            result(observer, serveResult)
                        case .stillConnected:
                            progress?(.success)
                            result(observer, serveResult)
                        case .bluetoothWasPoweredOff:
                            progress?(.success)
                            result(observer, serveResult)
                        case .failure(let error):
                            progress?(.failure(error))
                            result(observer, .failure(error))
                        }
                    }
                }
            case .failure(let error):
                progress?(.failure(error))
                result(observer, .failure(error))
            case .disconnected:
                break // do nothing, it will reconnect
            }
        })
    }

    private func serveFirmware<T: AnyObject>(_ observer: T, _ uuid: String, _ options: BTScannerOptionsInfo?, _ result: @escaping (T, Result<String, BTError>) -> Void) -> ObservationToken? {
        let info = BTKitParsedOptionsInfo(options)
        let serveToken = BTKit.background.scanner.serveGATT(observer, for: uuid, .deviceInformation(.firmwareRevision(.standard)), options: options, request: { (observer, peripheral, characteristic) in
            if let characteristic = characteristic {
                peripheral?.readValue(for: characteristic)
            } else {
                info.callbackQueue.execute {
                    result(observer, .failure(.unexpected(.characteristicIsNil)))
                }
            }
        }, response: { (observer, data, finished) in
            if let data = data {
                if let firmwareRevisionString = String(data: data, encoding: .utf8) {
                    result(observer, .success(firmwareRevisionString))
                } else {
                    result(observer, .failure(.unexpected(.dataIsNil)))
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

public struct BTKitRuuviNUSService {
    
    public func celisus<T: AnyObject>(for observer: T, uuid: String, from date: Date, options: BTScannerOptionsInfo? = nil, progress:((BTServiceProgress) -> Void)? = nil, result: @escaping (T, Result<[RuuviTagEnvLog], BTError>) -> Void) {
        serve(.temperature, for: observer, uuid: uuid, from: date, options: options, result: result)
    }
    
    
    public func humidity<T: AnyObject>(for observer: T, uuid: String, from date: Date, options: BTScannerOptionsInfo? = nil, progress:((BTServiceProgress) -> Void)? = nil, result: @escaping (T, Result<[RuuviTagEnvLog], BTError>) -> Void) {
        serve(.humidity, for: observer, uuid: uuid, from: date, options: options, result: result)
    }
    
    public func pressure<T: AnyObject>(for observer: T, uuid: String, from date: Date, options: BTScannerOptionsInfo? = nil, progress:((BTServiceProgress) -> Void)? = nil, result: @escaping (T, Result<[RuuviTagEnvLog], BTError>) -> Void) {
        serve(.pressure, for: observer, uuid: uuid, from: date, options: options, result: result)
    }
    
    public func log<T: AnyObject>(for observer: T, uuid: String, from date: Date, options: BTScannerOptionsInfo? = nil, progress:((BTServiceProgress) -> Void)? = nil, result: @escaping (T, Result<Progressable, BTError>) -> Void) {
        var connectToken: ObservationToken?
        progress?(.connecting)
        connectToken = BTKit.background.connect(for: observer, uuid: uuid, options: options, connected: { (observer, connectResult) in
            connectToken?.invalidate()
            switch connectResult {
            case .already:
                var serveToken: ObservationToken?
                progress?(.serving)
                serveToken = self.serveLogs(observer, uuid, options, date) { observer, serveResult in
                    var disconnectToken: ObservationToken?
                    switch serveResult {
                    case .success(.points(let points)):
                        progress?(.reading(points))
                    case .success(.logs):
                        serveToken?.invalidate()
                        progress?(.disconnecting)
                        disconnectToken = BTKit.background.disconnect(for: observer, uuid: uuid, options: options) { (observer, disconnectResult) in
                            disconnectToken?.invalidate()
                            switch disconnectResult {
                            case .already:
                                progress?(.success)
                                result(observer, serveResult)
                            case .just:
                                progress?(.success)
                                result(observer, serveResult)
                            case .stillConnected:
                                result(observer, serveResult)
                                progress?(.success)
                            case .bluetoothWasPoweredOff:
                                progress?(.success)
                                result(observer, serveResult)
                            case .failure(let error):
                                progress?(.failure(error))
                                result(observer, .failure(error))
                            }
                        }
                    case .failure:
                        break
                    }

                }
            case .just:
                var serveToken: ObservationToken?
                progress?(.serving)
                serveToken = self.serveLogs(observer, uuid, options, date) { observer, serveResult in
                    switch serveResult {
                    case .success(.points(let points)):
                        progress?(.reading(points))
                    case .success(.logs):
                        serveToken?.invalidate()
                        var disconnectToken: ObservationToken?
                        progress?(.disconnecting)
                        disconnectToken = BTKit.background.disconnect(for: observer, uuid: uuid, options: options) { (observer, disconnectResult) in
                            disconnectToken?.invalidate()
                            switch disconnectResult {
                            case .already:
                                progress?(.success)
                                result(observer, serveResult)
                            case .just:
                                progress?(.success)
                                result(observer, serveResult)
                            case .stillConnected:
                                progress?(.success)
                                result(observer, serveResult)
                            case .bluetoothWasPoweredOff:
                                progress?(.success)
                                result(observer, serveResult)
                            case .failure(let error):
                                progress?(.failure(error))
                                result(observer, .failure(error))
                            }
                        }
                    case .failure:
                        break
                    }
                }
            case .failure(let error):
                progress?(.failure(error))
                result(observer, .failure(error))
            case .disconnected:
                break // do nothing, it will reconnect
            }
        })
    }
    
    private func serveLogs<T: AnyObject>(_ observer: T, _ uuid: String, _ options: BTScannerOptionsInfo?, _ date: Date, _ result: @escaping (T, Result<Progressable, BTError>) -> Void) -> ObservationToken? {
        let info = BTKitParsedOptionsInfo(options)
        var values = [RuuviTagEnvLogFull]()
        var lastValue = RuuviTagEnvLogFullClass()
        let service: BTRuuviNUSService = .all
        let serveToken = BTKit.background.scanner.serveUART(observer, for: uuid, .ruuvi(.nus(service)), options: options, request: { (observer, peripheral, rx, tx) in
            if let rx = rx {
                peripheral?.writeValue(service.request(from: date), for: rx, type: .withResponse)
            } else {
                info.callbackQueue.execute {
                    result(observer, .failure(.unexpected(.characteristicIsNil)))
                }
            }
        }, response: { (observer, data, finished) in
            if let data = data {
                if service.isEndOfTransmissionFlag(data: data) {
                    finished?(true)
                    info.callbackQueue.execute {
                        result(observer, .success(.logs(values)))
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
                        result(observer, .success(.points(values.count)))
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
    
    fileprivate func serveEnv<T: AnyObject>(_ observer: T, _ uuid: String, _ service: BTRuuviNUSService, _ options: BTScannerOptionsInfo?, _ date: Date, _ result: @escaping (T, Result<[RuuviTagEnvLog], BTError>) -> Void) -> ObservationToken? {
        let info = BTKitParsedOptionsInfo(options)
        var values = [RuuviTagEnvLog]()
        let serveToken = BTKit.background.scanner.serveUART(observer, for: uuid, .ruuvi(.nus(service)), options: options, request: { (observer, peripheral, rx, tx) in
            if let rx = rx {
                peripheral?.writeValue(service.request(from: date), for: rx, type: .withResponse)
            } else {
                info.callbackQueue.execute {
                    result(observer, .failure(.unexpected(.characteristicIsNil)))
                }
            }
        }, response: { (observer, data, finished) in
            if let data = data {
                if service.isEndOfTransmissionFlag(data: data) {
                    finished?(true)
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
    
    private func serve<T: AnyObject>(_ service: BTRuuviNUSService, for observer: T, uuid: String, from date: Date, options: BTScannerOptionsInfo?, progress:((BTServiceProgress) -> Void)? = nil, result: @escaping (T, Result<[RuuviTagEnvLog], BTError>) -> Void) {
        
        var connectToken: ObservationToken?
        progress?(.connecting)
        connectToken = BTKit.background.connect(for: observer, uuid: uuid, options: options, connected: { (observer, connectResult) in
            connectToken?.invalidate()
            switch connectResult {
            case .already:
                var serveToken: ObservationToken?
                progress?(.serving)
                serveToken = self.serveEnv(observer, uuid, service, options, date) { observer, serveResult in
                    serveToken?.invalidate()
                    var disconnectToken: ObservationToken?
                    progress?(.disconnecting)
                    disconnectToken = BTKit.background.disconnect(for: observer, uuid: uuid, options: options) { (observer, disconnectResult) in
                        disconnectToken?.invalidate()
                        switch disconnectResult {
                        case .already:
                            progress?(.success)
                            result(observer, serveResult)
                        case .just:
                            progress?(.success)
                            result(observer, serveResult)
                        case .stillConnected:
                            progress?(.success)
                            result(observer, serveResult)
                        case .bluetoothWasPoweredOff:
                            progress?(.success)
                            result(observer, serveResult)
                        case .failure(let error):
                            progress?(.failure(error))
                            result(observer, .failure(error))
                        }
                    }
                }
            case .just:
                var serveToken: ObservationToken?
                progress?(.serving)
                serveToken = self.serveEnv(observer, uuid, service, options, date) { observer, serveResult in
                    serveToken?.invalidate()
                    var disconnectToken: ObservationToken?
                    progress?(.disconnecting)
                    disconnectToken = BTKit.background.disconnect(for: observer, uuid: uuid, options: options) { (observer, disconnectResult) in
                        disconnectToken?.invalidate()
                        switch disconnectResult {
                        case .already:
                            progress?(.success)
                            result(observer, serveResult)
                        case .just:
                            progress?(.success)
                            result(observer, serveResult)
                        case .stillConnected:
                            progress?(.success)
                            result(observer, serveResult)
                        case .bluetoothWasPoweredOff:
                            progress?(.success)
                            result(observer, serveResult)
                        case .failure(let error):
                            progress?(.failure(error))
                            result(observer, .failure(error))
                        }
                    }
                }
            case .failure(let error):
                progress?(.failure(error))
                result(observer, .failure(error))
            case .disconnected:
                break // do nothing, it will reconnect
            }
        })
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

