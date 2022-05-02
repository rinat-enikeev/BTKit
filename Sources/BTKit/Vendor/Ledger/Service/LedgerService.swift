import Foundation
import CoreBluetooth

public class LedgerService: BTUARTService {
    public let uuid = CBUUID(string: "13d63400-2c97-0004-0000-4c6564676572")
    public var rxUUID = CBUUID(string: "13d63400-2c97-0004-0002-4c6564676572")
    public var txUUID = CBUUID(string: "13d63400-2c97-0004-0001-4c6564676572")
    public var tx: CBCharacteristic?
    public var rx: CBCharacteristic?

    public init() {}
}
