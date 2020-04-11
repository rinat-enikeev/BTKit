import Foundation

public protocol BTData {
    var uuid: String { get }
    var rssi: Int { get }
}

public protocol BTDecoder {
    func decodeNetwork(uuid: String, rssi: Int, isConnectable: Bool, payload: String) -> BTDevice?
    func decodeHeartbeat(uuid: String, data: Data?) -> BTDevice?
    func decodeAdvertisement(uuid: String, rssi: NSNumber, advertisementData: [String : Any]) -> BTDevice?
}

public protocol BTVendor {
    static var eddystone: String { get }
    static var vendorId: Int { get }
}
