import Foundation

public struct BTBackground {
    public let scanner: BTBackgroundScanner = BTBackgroundScanneriOS(services: [RuuviNUSService()], decoders: [RuuviDecoderiOS()])
    
    public let services: BTServices = BTServices()
    
    @discardableResult
    public func disconnect<T:AnyObject>(for observer: T, uuid: String, options: BTScannerOptionsInfo? = nil, result: ((T, BTDisconnectResult) -> Void)?) -> ObservationToken? {
        if !scanner.isConnected(uuid: uuid) {
            let info = BTKitParsedOptionsInfo(options)
            info.callbackQueue.execute {
                result?(observer, .already)
            }
            return nil
        } else {
            return scanner.disconnect(observer, uuid: uuid, options: options, disconnected: { (observer, error) in
                if let error = error {
                    switch error {
                    case .logic(let logicError):
                        switch logicError {
                        case .connectedByOthers:
                            result?(observer, .connected)
                        default:
                            result?(observer, .failure(error))
                        }
                    default:
                        result?(observer, .failure(error))
                    }
                } else {
                    result?(observer, .just)
                }
            })
        }
    }
    
    @discardableResult
    public func connect<T: AnyObject>(for observer: T, uuid: String, options: BTScannerOptionsInfo? = nil, connected: ((T, BTConnectResult) -> Void)? = nil, heartbeat: ((T, BTDevice) -> Void)? = nil, disconnected: ((T, BTDisconnectResult) -> Void)? = nil) -> ObservationToken? {
        if scanner.isConnected(uuid: uuid) {
            let info = BTKitParsedOptionsInfo(options)
            info.callbackQueue.execute {
                connected?(observer, .already)
            }
            return nil
        } else {
            return scanner.connect(observer, uuid: uuid, options: options, connected: { observer, error in
                if let error = error {
                    connected?(observer, .failure(error))
                } else {
                    connected?(observer, .just)
                }
            }, heartbeat: { observer, device in
                heartbeat?(observer, device)
            }) { observer, error in
                if let error = error {
                    disconnected?(observer, .failure(error))
                } else {
                    disconnected?(observer, .just)
                }
            }
        }
    }
}
