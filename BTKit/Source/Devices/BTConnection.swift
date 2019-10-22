import Foundation

public struct BTConnection {
    
    private let backgroundScanner = BTBackgroundScanneriOS(service: RuuviNUSService())
    private let foregroundScanner = BTKit.scanner
    
    public func isConnected(uuid: String) -> Bool {
        return foregroundScanner.isConnected(uuid: uuid) || backgroundScanner.isConnected(uuid: uuid)
    }
    
    @discardableResult
    public func keep<T: AnyObject>(for observer: T, uuid: String, options: BTScannerOptionsInfo?, connected: @escaping (T, BTConnectResult) -> Void, heartbeat: @escaping (T, BTDevice) -> Void, disconnected: @escaping (T, BTDisconnectResult) -> Void) -> ObservationToken? {
        if isConnected(uuid: uuid) {
            let info = BTKitParsedOptionsInfo(options)
            info.callbackQueue.execute {
                connected(observer, .already)
            }
            return nil
        } else {
            return backgroundScanner.connect(observer, uuid: uuid, options: options, connected: { observer, error in
                if let error = error {
                    connected(observer, .failure(error))
                } else {
                    connected(observer, .just)
                }
            }, heartbeat: { observer, device in
                heartbeat(observer, device)
            }) { observer, error in
                if let error = error {
                    disconnected(observer, .failure(error))
                } else {
                    disconnected(observer, .just)
                }
            }
        }
    }
    
    @discardableResult
    public func establish<T: AnyObject>(for observer: T, uuid: String, options: BTScannerOptionsInfo?, result: @escaping (T, BTConnectResult) -> Void) -> ObservationToken? {
        if isConnected(uuid: uuid) {
            let info = BTKitParsedOptionsInfo(options)
            info.callbackQueue.execute {
                result(observer, .already)
            }
            return nil
        } else {
            let connectToken = foregroundScanner.connect(observer, uuid: uuid, options: options, connected: { (observer, error) in
                if let error = error {
                    result(observer, .failure(error))
                } else {
                    result(observer, .just)
                }
            }) { (observer, error) in
                if let error = error {
                    result(observer, .failure(error))
                } else {
                    result(observer, .disconnected)
                }
            }
            return connectToken
        }
    }
    
    @discardableResult
    public func drop<T:AnyObject>(for observer: T, uuid: String, options: BTScannerOptionsInfo?, result: @escaping (T, BTDisconnectResult) -> Void) -> ObservationToken? {
        if !isConnected(uuid: uuid) {
            let info = BTKitParsedOptionsInfo(options)
            info.callbackQueue.execute {
                result(observer, .already)
            }
            return nil
        } else {
            return foregroundScanner.disconnect(observer, uuid: uuid, options: options, disconnected: { (observer, error) in
                if let error = error {
                    result(observer, .failure(error))
                } else {
                    result(observer, .just)
                }
            })
        }
    }
    
}

public extension BTConnection {
    @discardableResult
    func establish<T: AnyObject>(for observer: T, uuid: String, result: @escaping (T, BTConnectResult) -> Void) -> ObservationToken? {
        return establish(for: observer, uuid: uuid, options: nil, result: result)
    }
    
    @discardableResult
    func drop<T:AnyObject>(for observer: T, uuid: String, result: @escaping (T, BTDisconnectResult) -> Void) -> ObservationToken? {
        return drop(for: observer, uuid: uuid, options: nil, result: result)
    }
    
    @discardableResult
    public func keep<T: AnyObject>(for observer: T, uuid: String, connected: @escaping (T, BTConnectResult) -> Void, heartbeat: @escaping (T, BTDevice) -> Void, disconnected: @escaping (T, BTDisconnectResult) -> Void) -> ObservationToken? {
        return keep(for: observer, uuid: uuid, options: nil, connected: connected, heartbeat: heartbeat, disconnected: disconnected)
    }
}
