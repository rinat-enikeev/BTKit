import Foundation
import CoreBluetooth

public enum BTServiceType {
    case ruuvi(BTRuuviServiceType)
    
    var uuid: CBUUID {
        switch self {
        case .ruuvi(let type):
            switch type {
            case .uart(let uuid):
                return uuid
            }
        }
    }
}

public enum BTRuuviServiceType {
    case uart(CBUUID)
    
    public static let NUS = CBUUID(string: "6E400001-B5A3-F393-E0A9-E50E24DCCA9E")
}

public protocol BTService: class {
    var uuid: CBUUID { get }
}

public protocol BTUARTService: BTService {
    var txUUID: CBUUID { get }
    var rxUUID: CBUUID { get }
    var tx: CBCharacteristic? { get set }
    var rx: CBCharacteristic? { get set }
    var isReady: Bool { get set }
}
