import Foundation

public struct BTKitBackground {
    public let ruuvi = BTKitRuuviBackground()
}

public struct BTKitRuuviBackground {
    public let heartbeat = BTKitRuuviHeartbeatBackground()
}

public struct BTKitRuuviHeartbeatBackground {
    
    private let nus = BTKit.backgroundScanner(for: RuuviNUSService())
    
    @discardableResult
    public func subscribe<T: AnyObject>(for observer: T, uuid: String, heartbeat: @escaping (T, (Date) -> ObservationToken?, Result<BTDevice, BTError>) -> Void) -> ObservationToken? {
        return subscribe(for: observer, uuid: uuid, options: nil, heartbeat: heartbeat, connected: nil, disconnected: nil, receiveLogs: nil)
    }
    
    @discardableResult
    public func subscribe<T: AnyObject>(for observer: T, uuid: String, heartbeat: @escaping (T, (Date) -> ObservationToken?, Result<BTDevice, BTError>) -> Void, connected: @escaping (T, (Date) -> ObservationToken?, BTError?) -> Void) -> ObservationToken? {
        return subscribe(for: observer, uuid: uuid, options: nil, heartbeat: heartbeat, connected: connected, disconnected: nil, receiveLogs: nil)
    }
    
    @discardableResult
    public func subscribe<T: AnyObject>(for observer: T, uuid: String, heartbeat: @escaping (T, (Date) -> ObservationToken?, Result<BTDevice, BTError>) -> Void, connected: @escaping (T, (Date) -> ObservationToken?, BTError?) -> Void, disconnected: ((T, BTError?) -> Void)?) -> ObservationToken? {
        return subscribe(for: observer, uuid: uuid, options: nil, heartbeat: heartbeat, connected: connected, disconnected: disconnected, receiveLogs: nil)
    }
    
    @discardableResult
    public func subscribe<T: AnyObject>(for observer: T, uuid: String, heartbeat: @escaping (T, (Date) -> ObservationToken?, Result<BTDevice, BTError>) -> Void, connected: @escaping (T, (Date) -> ObservationToken?, BTError?) -> Void, receiveLogs: ((T, Result<[RuuviTagEnvLogFull], BTError>) -> Void)?) -> ObservationToken?  {
        return subscribe(for: observer, uuid: uuid, options: nil, heartbeat: heartbeat, connected: connected, disconnected: nil, receiveLogs: receiveLogs)
    }
    
    @discardableResult
    public func subscribe<T: AnyObject>(for observer: T, uuid: String, options: BTScannerOptionsInfo?, heartbeat: @escaping (T, (Date) -> ObservationToken?, Result<BTDevice, BTError>) -> Void, connected: ((T, (Date) -> ObservationToken?, BTError?) -> Void)?, disconnected: ((T, BTError?) -> Void)?, receiveLogs: ((T, Result<[RuuviTagEnvLogFull], BTError>) -> Void)?) -> ObservationToken? {
        
        let info = BTKitParsedOptionsInfo(options)
        let readLogs: (Date) -> ObservationToken? = { [weak observer] date in
            guard let observer = observer else { return nil }
            var values = [RuuviTagEnvLogFull]()
            var lastValue = RuuviTagEnvLogFullClass()
            let service: BTRuuviNUSService = .all
            let serveToken = self.nus.serve(observer, for: uuid, .ruuvi(.uart(service)), options: options, request: { (observer, peripheral, rx, tx) in
                if let rx = rx {
                    peripheral?.writeValue(service.request(from: date), for: rx, type: .withResponse)
                } else {
                    info.callbackQueue.execute {
                        receiveLogs?(observer, .failure(.unexpected(.characteristicIsNil)))
                    }
                }
            }, response: { (observer, data) in
                if let data = data {
                    if service.isEndOfTransmissionFlag(data: data) {
                        info.callbackQueue.execute {
                            receiveLogs?(observer, .success(values))
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
                        receiveLogs?(observer, .failure(.unexpected(.dataIsNil)))
                    }
                }
            }) { (observer, error) in
                info.callbackQueue.execute {
                    receiveLogs?(observer, .failure(error))
                }
            }
            return serveToken
        }
        let token = nus.connect(observer, uuid: uuid, options: options, connected: { (observer, error) in
            connected?(observer, readLogs, error)
        }, heartbeat: { (observer, device) in
            heartbeat(observer, readLogs, .success(device))
        }, disconnected: { (observer, error) in
            disconnected?(observer, error)
        })
        return token
    }
    
    
    @discardableResult
    public func unsubscribe<T:AnyObject>(for observer: T, uuid: String, result: @escaping (T, BTDisconnectResult) -> Void) -> ObservationToken? {
        return unsubscribe(for: observer, uuid: uuid, options: nil, result: result)
    }
    
    @discardableResult
    public func unsubscribe<T:AnyObject>(for observer: T, uuid: String, options: BTScannerOptionsInfo?, result: @escaping (T, BTDisconnectResult) -> Void) -> ObservationToken? {
        if !nus.isConnected(uuid: uuid) {
            let info = BTKitParsedOptionsInfo(options)
            info.callbackQueue.execute {
                result(observer, .already)
            }
            return nil
        } else {
            return nus.disconnect(observer, uuid: uuid, options: options, disconnected: { (observer, error) in
                if let error = error {
                    result(observer, .failure(error))
                } else {
                    result(observer, .just)
                }
            })
        }
    }
}
