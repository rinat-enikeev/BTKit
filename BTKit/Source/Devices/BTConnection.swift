import Foundation

public struct BTKitConnection {
    @discardableResult
    public func establish<T: AnyObject>(for observer: T, uuid: String, options: BTScannerOptionsInfo?, result: @escaping (T, BTConnectResult) -> Void) -> ObservationToken? {
        if BTKit.scanner.isConnected(uuid: uuid) {
            let info = BTKitParsedOptionsInfo(options)
            info.callbackQueue.execute {
                result(observer, .already)
            }
            return nil
        } else {
            let connectToken = BTKit.scanner.connect(observer, uuid: uuid, options: options, connected: { (observer, error) in
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
        if !BTKit.scanner.isConnected(uuid: uuid) {
            let info = BTKitParsedOptionsInfo(options)
            info.callbackQueue.execute {
                result(observer, .already)
            }
            return nil
        } else {
            return BTKit.scanner.disconnect(observer, uuid: uuid, options: options, disconnected: { (observer, error) in
                if let error = error {
                    result(observer, .failure(error))
                } else {
                    result(observer, .just)
                }
            })
        }
    }
    
}

public extension BTKitConnection {
    @discardableResult
    func establish<T: AnyObject>(for observer: T, uuid: String, result: @escaping (T, BTConnectResult) -> Void) -> ObservationToken? {
        return establish(for: observer, uuid: uuid, options: nil, result: result)
    }
    
    @discardableResult
    func drop<T:AnyObject>(for observer: T, uuid: String, result: @escaping (T, BTDisconnectResult) -> Void) -> ObservationToken? {
        return drop(for: observer, uuid: uuid, options: nil, result: result)
    }
}
