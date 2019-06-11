public protocol BTData {
    var uuid: String { get }
    var rssi: Int { get }
}

public protocol BTDecoder {
    func decode(uuid: String, rssi: NSNumber, advertisementData: [String : Any]) -> BTDevice?
}

public protocol BTVendor {
    static var eddystone: String { get }
    static var vendorId: Int { get }
}
