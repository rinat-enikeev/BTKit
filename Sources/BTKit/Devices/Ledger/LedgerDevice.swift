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
