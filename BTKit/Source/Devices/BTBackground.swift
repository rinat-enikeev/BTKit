import Foundation

public struct BTBackground {
    public let scanner: BTBackgroundScanner = BTBackgroundScanneriOS(services: [RuuviNUSService()], decoders: [RuuviDecoderiOS()])
    
    @discardableResult
    public func disconnect<T:AnyObject>(for observer: T, uuid: String, options: BTScannerOptionsInfo?, result: @escaping (T, BTDisconnectResult) -> Void) -> ObservationToken? {
        if !scanner.isConnected(uuid: uuid) {
            let info = BTKitParsedOptionsInfo(options)
            info.callbackQueue.execute {
                result(observer, .already)
            }
            return nil
        } else {
            return scanner.disconnect(observer, uuid: uuid, options: options, disconnected: { (observer, error) in
                if let error = error {
                    result(observer, .failure(error))
                } else {
                    result(observer, .just)
                }
            })
        }
    }
    
    @discardableResult
    public func connect<T: AnyObject>(for observer: T, uuid: String, options: BTScannerOptionsInfo?, connected: @escaping (T, BTConnectResult) -> Void, heartbeat: @escaping (T, BTDevice) -> Void, disconnected: @escaping (T, BTDisconnectResult) -> Void) -> ObservationToken? {
        if scanner.isConnected(uuid: uuid) {
            let info = BTKitParsedOptionsInfo(options)
            info.callbackQueue.execute {
                connected(observer, .already)
            }
            return nil
        } else {
            return scanner.connect(observer, uuid: uuid, options: options, connected: { observer, error in
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
}

extension BTBackground {
    @discardableResult
    public func disconnect<T:AnyObject>(for observer: T, uuid: String, result: @escaping (T, BTDisconnectResult) -> Void) -> ObservationToken? {
        return disconnect(for: observer, uuid: uuid, options: nil, result: result)
    }
    
    @discardableResult
    public func connect<T: AnyObject>(for observer: T, uuid: String, connected: @escaping (T, BTConnectResult) -> Void, heartbeat: @escaping (T, BTDevice) -> Void, disconnected: @escaping (T, BTDisconnectResult) -> Void) -> ObservationToken? {
        return connect(for: observer, uuid: uuid, options: nil, connected: connected, heartbeat: heartbeat, disconnected: disconnected)
    }
}
