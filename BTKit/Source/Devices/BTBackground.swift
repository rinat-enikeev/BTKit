import Foundation

public struct BTBackground {
    
    public static let shared = BTBackground()
    
    let scanner: BTBackgroundScanner = BTBackgroundScanneriOS(services: [RuuviNUSService()], decoders: [RuuviDecoderiOS()])
    
    public let services: BTServices = BTServices()
    
    @discardableResult
    public func readRSSI<T: AnyObject>(for observer: T, uuid: String, options: BTScannerOptionsInfo? = nil, result: @escaping (T, Result<Int,BTError>) -> Void) -> ObservationToken? {
        if scanner.isConnected(uuid: uuid) {
            return scanner.readRSSI(observer, uuid: uuid, options: options) { (observer, RSSI, error) in
                if let error = error {
                    result(observer, .failure(error))
                } else if let RSSI = RSSI {
                    result(observer, .success(RSSI.intValue))
                } else {
                    result(observer, .failure(.unexpected(.bothResultAndErrorAreNil)))
                }
            }
        } else {
            result(observer, .failure(.logic(.notConnected)))
            return nil
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
                    switch error {
                    case .logic(let logicError):
                        switch logicError {
                        case .connectedByOthers:
                            disconnected?(observer, .stillConnected)
                        case .bluetoothWasPoweredOff:
                            disconnected?(observer, .bluetoothWasPoweredOff)
                        default:
                            disconnected?(observer, .failure(error))
                        }
                    default:
                        disconnected?(observer, .failure(error))
                    }
                } else {
                    disconnected?(observer, .just)
                }
            }
        }
    }
    
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
                            result?(observer, .stillConnected)
                        case .bluetoothWasPoweredOff:
                            result?(observer, .bluetoothWasPoweredOff)
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
    public func observe<T: AnyObject>(_ observer: T, uuid: String, options: BTScannerOptionsInfo? = nil, closure: @escaping (T, BTDevice) -> Void) -> ObservationToken {
        return scanner.observe(observer, uuid: uuid, options: options, closure: closure)
    }
}
