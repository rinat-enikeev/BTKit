public enum LedgerDevice {
    case nanoX(LedgerNanoX)
}

public struct LedgerNanoX: Hashable {
    public var uuid: String
    public var name: String?
    public var rssi: Int?
    public var isConnectable: Bool

    public init(
        uuid: String,
        name: String?,
        rssi: Int?,
        isConnectable: Bool
    ) {
        self.uuid = uuid
        self.name = name
        self.rssi = rssi
        self.isConnectable = isConnectable
    }
}

public extension LedgerNanoX {
    func address<T: AnyObject>(for observer: T, options: BTScannerOptionsInfo? = nil, path: String, verify: Bool, result: @escaping (T, Result<LedgerAddressResult, BTError>) -> Void) {
        if !isConnectable {
            let info = BTKitParsedOptionsInfo(options)
            info.callbackQueue.execute {
                result(observer, .failure(.logic(.notConnectable)))
            }
        } else {
            BTKit.background.services.ledger.fetchAddress(observer, uuid, options, path: path, verify, result)
        }
    }

}
