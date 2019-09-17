public struct BTKit {   
    public static let scanner: BTScanner = BTScanneriOS(decoders: [RuuviDecoderiOS()], services: [RuuviNUSService()])
    
    public static let service: BTKitService = BTKitService()
    
    public static let connection: BTKitConnection = BTKitConnection()
}

public struct BTKitConnection {
    @discardableResult
    public func establish<T: AnyObject>(for observer: T, uuid: String, result: @escaping (T, BTConnectResult) -> Void) -> ObservationToken? {
        if BTKit.scanner.isConnected(uuid: uuid) {
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
    
    @discardableResult
    public func drop<T:AnyObject>(for observer: T, uuid: String, result: @escaping (T, BTDisconnectResult) -> Void) -> ObservationToken? {
        if !BTKit.scanner.isConnected(uuid: uuid) {
            result(observer, .already)
            return nil
        } else {
            return BTKit.scanner.disconnect(observer, uuid: uuid, disconnected: { (observer) in
                result(observer, .just)
            })
        }
    }
    
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
        return serve(.temperature, for: observer, uuid: uuid, from: date, result: result)
    }
    
    @discardableResult
    public func humidity<T: AnyObject>(for observer: T, uuid: String, from date: Date, result: @escaping (T, Result<[RuuviTagEnvLog], BTError>) -> Void) -> ObservationToken? {
        return serve(.humidity, for: observer, uuid: uuid, from: date, result: result)
    }
    
    @discardableResult
    public func pressure<T: AnyObject>(for observer: T, uuid: String, from date: Date, result: @escaping (T, Result<[RuuviTagEnvLog], BTError>) -> Void) -> ObservationToken? {
        return serve(.pressure, for: observer, uuid: uuid, from: date, result: result)
    }
    
    @discardableResult
    public func log<T: AnyObject>(for observer: T, uuid: String, from date: Date, result: @escaping (T, Result<[RuuviTagEnvLogFull], BTError>) -> Void) -> ObservationToken? {
        if !BTKit.scanner.isConnected(uuid: uuid) {
            result(observer, .failure(.logic(.notConnected)))
            return nil
        } else {
            var values = [RuuviTagEnvLogFull]()
            var lastValue = RuuviTagEnvLogFullClass()
            let service: BTRuuviNUSService = .all
            let serveToken = BTKit.scanner.serve(observer, for: uuid, .ruuvi(.uart(service)), request: { (observer, peripheral, rx, tx) in
                if let rx = rx {
                    peripheral?.writeValue(service.request(from: date), for: rx, type: .withResponse)
                } else {
                    result(observer, .failure(.unexpected(.characteristicIsNil)))
                }
            }, response: { (observer, data) in
                if let data = data {
                    if service.isEndOfTransmissionFlag(data: data) {
                        result(observer, .success(values))
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
                    result(observer, .failure(.unexpected(.dataIsNil)))
                }
            }) { (observer, error) in
                result(observer, .failure(error))
            }
            return serveToken
        }
    }
    
    private func serve<T: AnyObject>(_ service: BTRuuviNUSService, for observer: T, uuid: String, from date: Date, result: @escaping (T, Result<[RuuviTagEnvLog], BTError>) -> Void) -> ObservationToken? {
        if !BTKit.scanner.isConnected(uuid: uuid) {
            result(observer, .failure(.logic(.notConnected)))
            return nil
        } else {
            var values = [RuuviTagEnvLog]()
            let serveToken = BTKit.scanner.serve(observer, for: uuid, .ruuvi(.uart(service)), request: { (observer, peripheral, rx, tx) in
                if let rx = rx {
                    peripheral?.writeValue(service.request(from: date), for: rx, type: .withResponse)
                } else {
                    result(observer, .failure(.unexpected(.characteristicIsNil)))
                }
            }, response: { (observer, data) in
                if let data = data {
                    if service.isEndOfTransmissionFlag(data: data) {
                        result(observer, .success(values))
                    } else if let row = service.response(from: data) {
                        values.append(RuuviTagEnvLog(type: service, date: row.0, value: row.1))
                    }
                } else {
                    result(observer, .failure(.unexpected(.dataIsNil)))
                }
            }) { (observer, error) in
                result(observer, .failure(error))
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

