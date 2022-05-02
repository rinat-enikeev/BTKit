import CoreBluetooth

public struct LedgerDecoderiOS: BTDecoder {
    private let ledgerService = LedgerService()

    public init() {
    }

    public func decodeNetwork(uuid: String, rssi: Int, isConnectable: Bool, payload: String) -> BTDevice? {
        return nil
    }

    public func decodeHeartbeat(uuid: String, data: Data?) -> BTDevice? {
        return nil
    }

    public func decodeAdvertisement(uuid: String, rssi: NSNumber, advertisementData: [String : Any]) -> BTDevice? {
        if let services = advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID],
           services.contains(ledgerService.uuid) {
            let name = advertisementData[CBAdvertisementDataLocalNameKey] as? String
            let isConnectable = (advertisementData[CBAdvertisementDataIsConnectable] as? NSNumber)?.boolValue ?? false
            return .ledger(
                .nanoX(
                    LedgerNanoX(
                        uuid: uuid,
                        name: name,
                        rssi: rssi.intValue,
                        isConnectable: isConnectable
                    )
                )
            )
        } else {
            return nil
        }
    }
}
