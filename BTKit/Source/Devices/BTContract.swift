public protocol BTData {
    var uuid: String { get }
    var rssi: Int { get }
}

public protocol BTScanner {
    init(decoders: [BTDecoder])
    
    @discardableResult
    func observeDevice<T: AnyObject>(_ observer: T, closure: @escaping (T, BTDevice) -> Void) -> ObservationToken
    @discardableResult
    func observeState<T: AnyObject>(_ observer: T, closure: @escaping (T, BTScannerState) -> Void) -> ObservationToken
}

public protocol BTDecoder {
    func decode(uuid: String, rssi: NSNumber, advertisementData: [String : Any]) -> BTDevice?
}

public protocol BTVendor {
    static var eddystone: String { get }
    static var vendorId: Int { get }
}

public enum BTScannerState : Int {
    case unknown
    case resetting
    case unsupported
    case unauthorized
    case poweredOff
    case poweredOn
}

