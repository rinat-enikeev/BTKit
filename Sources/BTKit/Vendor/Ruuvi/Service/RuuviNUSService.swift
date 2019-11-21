import Foundation
import CoreBluetooth

public class RuuviNUSService: BTUARTService {
    public let uuid = CBUUID(string: "6E400001-B5A3-F393-E0A9-E50E24DCCA9E")
    public var rxUUID = CBUUID(string: "6E400002-B5A3-F393-E0A9-E50E24DCCA9E")
    public var txUUID = CBUUID(string: "6E400003-B5A3-F393-E0A9-E50E24DCCA9E")
    public var tx: CBCharacteristic?
    public var rx: CBCharacteristic?
    
    public init() {
        
    }
}
