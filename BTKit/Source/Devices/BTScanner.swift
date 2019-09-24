import CoreBluetooth

public protocol BTScanner {
    init(decoders: [BTDecoder], services: [BTService])
    
    var bluetoothState: BTScannerState { get }
    
    func isConnected(uuid: String) -> Bool
    
    @discardableResult
    func scan<T: AnyObject>(_ observer: T, options: BTScannerOptionsInfo?, closure: @escaping (T, BTDevice) -> Void) -> ObservationToken
    @discardableResult
    func state<T: AnyObject>(_ observer: T, options: BTScannerOptionsInfo?, closure: @escaping (T, BTScannerState) -> Void) -> ObservationToken
    @discardableResult
    func lost<T: AnyObject>(_ observer: T, options: BTScannerOptionsInfo?, closure: @escaping (T, BTDevice) -> Void) -> ObservationToken
    @discardableResult
    func observe<T: AnyObject>(_ observer: T, uuid: String, options: BTScannerOptionsInfo?, closure: @escaping (T, BTDevice) -> Void) -> ObservationToken
    @discardableResult
    func connect<T: AnyObject>(_ observer: T, uuid: String, options: BTScannerOptionsInfo?, connected: @escaping (T, BTError?) -> Void, disconnected: @escaping (T, BTError?) -> Void) -> ObservationToken
    @discardableResult
    func serve<T: AnyObject>(_ observer: T, for uuid: String, _ type: BTServiceType, options: BTScannerOptionsInfo?, request: ((T, CBPeripheral?, CBCharacteristic?, CBCharacteristic?) -> Void)?, response: ((T, Data?) -> Void)?, failure: ((T, BTError) -> Void)?) -> ObservationToken
    func disconnect<T: AnyObject>(_ observer: T, uuid: String, options: BTScannerOptionsInfo?, disconnected: @escaping (T, BTError?) -> Void) -> ObservationToken
}

public extension BTScanner {
    @discardableResult
    func scan<T: AnyObject>(_ observer: T, closure: @escaping (T, BTDevice) -> Void) -> ObservationToken {
        return scan(observer, options: nil, closure: closure)
    }
    
    @discardableResult
    func state<T: AnyObject>(_ observer: T, closure: @escaping (T, BTScannerState) -> Void) -> ObservationToken {
        return state(observer, options: nil, closure: closure)
    }
    
    @discardableResult
    func lost<T: AnyObject>(_ observer: T, closure: @escaping (T, BTDevice) -> Void) -> ObservationToken {
        return lost(observer, options: nil, closure: closure)
    }
    
    @discardableResult
    func observe<T: AnyObject>(_ observer: T, uuid: String, closure: @escaping (T, BTDevice) -> Void) -> ObservationToken {
        return observe(observer, uuid: uuid, options: nil, closure: closure)
    }
    
    @discardableResult
    func connect<T: AnyObject>(_ observer: T, uuid: String, connected: @escaping (T, BTError?) -> Void, disconnected: @escaping (T, BTError?) -> Void) -> ObservationToken {
        return connect(observer, uuid: uuid, options: nil, connected: connected, disconnected: disconnected)
    }
    
    @discardableResult
    func serve<T: AnyObject>(_ observer: T, for uuid: String, _ type: BTServiceType, request: ((T, CBPeripheral?, CBCharacteristic?, CBCharacteristic?) -> Void)?, response: ((T, Data?) -> Void)?, failure: ((T, BTError) -> Void)?) -> ObservationToken {
        return serve(observer, for: uuid, type, options: nil, request: request, response: response, failure: failure)
    }
    
    @discardableResult
    func disconnect<T: AnyObject>(_ observer: T, uuid: String, disconnected: @escaping (T, BTError?) -> Void) -> ObservationToken {
        return disconnect(observer, uuid: uuid, options: nil, disconnected: disconnected)
    }
}

public enum BTScannerState : Int {
    case unknown
    case resetting
    case unsupported
    case unauthorized
    case poweredOff
    case poweredOn
}

