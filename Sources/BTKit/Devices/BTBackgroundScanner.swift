import Foundation
import CoreBluetooth

public protocol BTBackgroundScanner {
    func isConnected(uuid: String) -> Bool
    
    @discardableResult
    func state<T: AnyObject>(_ observer: T, options: BTScannerOptionsInfo?, closure: @escaping (T, BTScannerState) -> Void) -> ObservationToken
    
    @discardableResult
    func connect<T: AnyObject>(_ observer: T, uuid: String,
                               options: BTScannerOptionsInfo?,
                               connected: @escaping (T, BTError?) -> Void,
                               heartbeat: @escaping (T, BTDevice) -> Void,
                               disconnected: @escaping (T, BTError?) -> Void) -> ObservationToken
    
    @discardableResult
    func disconnect<T: AnyObject>(_ observer: T, uuid: String, options: BTScannerOptionsInfo?, disconnected: @escaping (T, BTError?) -> Void) -> ObservationToken
    
    @discardableResult
    func serveUART<T: AnyObject>(_ observer: T, for uuid: String, _ type: BTServiceType, options: BTScannerOptionsInfo?, request: ((T, CBPeripheral?, CBCharacteristic?, CBCharacteristic?) -> Void)?, response: ((T, Data?, ((Bool) -> Void)?) -> Void)?, failure: ((T, BTError) -> Void)?) -> ObservationToken

    @discardableResult
    func serveGATT<T: AnyObject>(_ observer: T, for uuid: String, _ type: BTGATTServiceType, options: BTScannerOptionsInfo?, request: ((T, CBPeripheral?, CBCharacteristic?) -> Void)?, response: ((T, Data?, ((Bool) -> Void)?) -> Void)?, failure: ((T, BTError) -> Void)?) -> ObservationToken

    @discardableResult
    func serveLedger<T: AnyObject>(_ observer: T, for uuid: String, _ type: BTServiceType, options: BTScannerOptionsInfo?, request: ((T, CBPeripheral?, CBCharacteristic?, CBCharacteristic?) -> Void)?, response: ((T, Data?, ((Bool) -> Void)?) -> Void)?, failure: ((T, BTError) -> Void)?) -> ObservationToken

    @discardableResult
    func observe<T: AnyObject>(_ observer: T, uuid: String, options: BTScannerOptionsInfo?, closure: @escaping (T, BTDevice) -> Void) -> ObservationToken
    
    @discardableResult
    func readRSSI<T: AnyObject>(_ observer: T, uuid: String, options: BTScannerOptionsInfo?, closure: @escaping (T, NSNumber?, BTError?) -> Void
        ) -> ObservationToken
}

public extension BTBackgroundScanner {
    
    @discardableResult
    func state<T: AnyObject>(_ observer: T, closure: @escaping (T, BTScannerState) -> Void) -> ObservationToken {
        return state(observer, options: nil, closure: closure)
    }
    
    @discardableResult
    func connect<T: AnyObject>(_ observer: T, uuid: String,
                               connected: @escaping (T, BTError?) -> Void,
                               heartbeat: @escaping (T, BTDevice) -> Void,
                               disconnected: @escaping (T, BTError?) -> Void) -> ObservationToken {
        return connect(observer, uuid: uuid, options: nil, connected: connected, heartbeat: heartbeat, disconnected: disconnected)
    }
    
    @discardableResult
    func disconnect<T: AnyObject>(_ observer: T, uuid: String, disconnected: @escaping (T, BTError?) -> Void) -> ObservationToken {
        return disconnect(observer, uuid: uuid, options: nil, disconnected: disconnected)
    }
    
    @discardableResult
    func serveUART<T: AnyObject>(_ observer: T, for uuid: String, _ type: BTServiceType, request: ((T, CBPeripheral?, CBCharacteristic?, CBCharacteristic?) -> Void)?, response: ((T, Data?, ((Bool) -> Void)?) -> Void)?, failure: ((T, BTError) -> Void)?) -> ObservationToken {
        return serveUART(observer, for: uuid, type, options: nil, request: request, response: response, failure: failure)
    }

    @discardableResult
    func serveGATT<T: AnyObject>(_ observer: T, for uuid: String, _ type: BTGATTServiceType, request: ((T, CBPeripheral?, CBCharacteristic?) -> Void)?, response: ((T, Data?, ((Bool) -> Void)?) -> Void)?, failure: ((T, BTError) -> Void)?) -> ObservationToken {
        return serveGATT(observer, for: uuid, type, options: nil, request: request, response: response, failure: failure)
    }
    
    @discardableResult
    func observe<T: AnyObject>(_ observer: T, uuid: String, closure: @escaping (T, BTDevice) -> Void) -> ObservationToken {
        return observe(observer, uuid: uuid, options: nil, closure: closure)
    }
    
    @discardableResult
    func readRSSI<T: AnyObject>(_ observer: T, uuid: String, closure: @escaping (T, NSNumber?, BTError?) -> Void
    ) -> ObservationToken {
        return readRSSI(observer, uuid: uuid, options: nil, closure: closure)
    }
}
