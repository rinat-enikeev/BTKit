public struct BTForeground {
    public let scanner: BTScanner = BTScanneriOS(decoders: [RuuviDecoderiOS()],
                                                 services: [RuuviNUSService()])
    
    @discardableResult
    public func connect<T: AnyObject>(for observer: T, uuid: String, options: BTScannerOptionsInfo?, result: @escaping (T, BTConnectResult) -> Void) -> ObservationToken? {
        if scanner.isConnected(uuid: uuid) {
            let info = BTKitParsedOptionsInfo(options)
            info.callbackQueue.execute {
                result(observer, .already)
            }
            return nil
        } else {
            let connectToken = scanner.connect(observer, uuid: uuid, options: options, connected: { (observer, error) in
                if let error = error {
                    result(observer, .failure(error))
                } else {
                    result(observer, .just)
                }
            }, disconnected: { (observer, error) in
                if let error = error {
                    result(observer, .failure(error))
                } else {
                    result(observer, .disconnected)
                }
            })
            return connectToken
        }
    }
    
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
}

extension BTForeground {
    @discardableResult
    public func connect<T: AnyObject>(for observer: T, uuid: String, result: @escaping (T, BTConnectResult) -> Void) -> ObservationToken? {
        return connect(for: observer, uuid: uuid, options: nil, result: result)
    }
    
    @discardableResult
    public func disconnect<T:AnyObject>(for observer: T, uuid: String, result: @escaping (T, BTDisconnectResult) -> Void) -> ObservationToken? {
        return disconnect(for: observer, uuid: uuid, options: nil, result: result)
    }
}
