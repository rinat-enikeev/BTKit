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
    public func subscribe<T: AnyObject>(for observer: T, uuid: String, heartbeat: @escaping (T, Result<RuuviTag, BTError>) -> Void) -> ObservationToken? {
        return subscribe(for: observer, uuid: uuid, options: nil, heartbeat: heartbeat)
    }
    
    @discardableResult
    public func subscribe<T: AnyObject>(for observer: T, uuid: String, options: BTScannerOptionsInfo?, heartbeat: @escaping (T, Result<RuuviTag, BTError>) -> Void) -> ObservationToken? {
        let token = nus.connect(observer, uuid: uuid, options: options, connected: { (observer, error) in
            if let error = error {
                heartbeat(observer, .failure(error))
            }
        }, heartbeat: { (observer, data, error) in
            if let error = error {
                heartbeat(observer, .failure(error))
            } else {
                if let ruuviTag = DemoFactory.shared.build(for: uuid).ruuvi?.tag {
                    heartbeat(observer, .success(ruuviTag))
                }
            }
        }) { (observer, error) in
            if let error = error {
                heartbeat(observer, .failure(error))
            }
        }
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
