public protocol BTScanner {
    init(decoders: [BTDecoder])
    
    var bluetoothState: BTScannerState { get }
    
    @discardableResult
    func scan<T: AnyObject>(_ observer: T, options: BTScannerOptionsInfo?, closure: @escaping (T, BTDevice) -> Void) -> ObservationToken
    @discardableResult
    func state<T: AnyObject>(_ observer: T, options: BTScannerOptionsInfo?, closure: @escaping (T, BTScannerState) -> Void) -> ObservationToken
    @discardableResult
    func lost<T: AnyObject>(_ observer: T, options: BTScannerOptionsInfo?, closure: @escaping (T, BTDevice) -> Void) -> ObservationToken
    @discardableResult
    func observe<T: AnyObject>(_ observer: T, uuid: String, options: BTScannerOptionsInfo?, closure: @escaping (T, BTDevice) -> Void) -> ObservationToken
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
}

public enum BTScannerState : Int {
    case unknown
    case resetting
    case unsupported
    case unauthorized
    case poweredOff
    case poweredOn
}

