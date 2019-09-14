import Foundation
import CoreBluetooth

class RuuviNUSService: BTUARTService {
    let uuid = CBUUID(string: "6E400001-B5A3-F393-E0A9-E50E24DCCA9E")
    var rxUUID = CBUUID(string: "6E400002-B5A3-F393-E0A9-E50E24DCCA9E")
    var txUUID = CBUUID(string: "6E400003-B5A3-F393-E0A9-E50E24DCCA9E")
    var tx: CBCharacteristic?
    var rx: CBCharacteristic?
    var isReady = false
}
