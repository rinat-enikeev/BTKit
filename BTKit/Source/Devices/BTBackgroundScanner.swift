import Foundation
import CoreBluetooth

public protocol BTBackgroundScanner {
    func isConnected(uuid: String) -> Bool
    
    @discardableResult
    func connect<T: AnyObject>(_ observer: T, uuid: String,
                               options: BTScannerOptionsInfo?,
                               connected: @escaping (T, BTError?) -> Void,
                               heartbeat: @escaping (T, Data?, BTError?) -> Void,
                               disconnected: @escaping (T, BTError?) -> Void) -> ObservationToken
    
    @discardableResult
    func disconnect<T: AnyObject>(_ observer: T, uuid: String, options: BTScannerOptionsInfo?, disconnected: @escaping (T, BTError?) -> Void) -> ObservationToken
    
    @discardableResult
    func serve<T: AnyObject>(_ observer: T, for uuid: String, _ type: BTServiceType, options: BTScannerOptionsInfo?, request: ((T, CBPeripheral?, CBCharacteristic?, CBCharacteristic?) -> Void)?, response: ((T, Data?) -> Void)?, failure: ((T, BTError) -> Void)?) -> ObservationToken
}

public extension BTBackgroundScanner {
    @discardableResult
    func connect<T: AnyObject>(_ observer: T, uuid: String,
                               connected: @escaping (T, BTError?) -> Void,
                               heartbeat: @escaping (T, Data?, BTError?) -> Void,
                               disconnected: @escaping (T, BTError?) -> Void) -> ObservationToken {
        return connect(observer, uuid: uuid, options: nil, connected: connected, heartbeat: heartbeat, disconnected: disconnected)
    }
    
    @discardableResult
    func disconnect<T: AnyObject>(_ observer: T, uuid: String, disconnected: @escaping (T, BTError?) -> Void) -> ObservationToken {
        return disconnect(observer, uuid: uuid, options: nil, disconnected: disconnected)
    }
    
    @discardableResult
    func serve<T: AnyObject>(_ observer: T, for uuid: String, _ type: BTServiceType, request: ((T, CBPeripheral?, CBCharacteristic?, CBCharacteristic?) -> Void)?, response: ((T, Data?) -> Void)?, failure: ((T, BTError) -> Void)?) -> ObservationToken {
        return serve(observer, for: uuid, type, options: nil, request: request, response: response, failure: failure)
    }
}
