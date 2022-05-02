public struct BTForeground {
    public static let shared = BTForeground()
    
    let scanner: BTScanner = BTScanneriOS(decoders: [LedgerDecoderiOS(), RuuviDecoderiOS()])
    
    public var bluetoothState: BTScannerState { return scanner.bluetoothState }
    
    @discardableResult
    public func scan<T: AnyObject>(_ observer: T, options: BTScannerOptionsInfo? = nil, closure: @escaping (T, BTDevice) -> Void) -> ObservationToken {
        return scanner.scan(observer, options: options, closure: closure)
    }
    
    @discardableResult
    public func state<T: AnyObject>(_ observer: T, options: BTScannerOptionsInfo? = nil, closure: @escaping (T, BTScannerState) -> Void) -> ObservationToken {
        return scanner.state(observer, options: options, closure: closure)
    }
    
    @discardableResult
    public func lost<T: AnyObject>(_ observer: T, options: BTScannerOptionsInfo? = nil, closure: @escaping (T, BTDevice) -> Void) -> ObservationToken {
        return scanner.lost(observer, options: options, closure: closure)
    }
    
    @discardableResult
    public func observe<T: AnyObject>(_ observer: T, uuid: String, options: BTScannerOptionsInfo? = nil, closure: @escaping (T, BTDevice) -> Void) -> ObservationToken {
        return scanner.observe(observer, uuid: uuid, options: options, closure: closure)
    }
    
    @discardableResult
    public func unknown<T: AnyObject>(_ observer: T, options: BTScannerOptionsInfo? = nil, closure: @escaping (T, BTUnknownDevice) -> Void) -> ObservationToken {
        return scanner.unknown(observer, options: options, closure: closure)
    }
}
