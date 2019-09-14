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
    
    public static func nusTemperatureHistoryRequest(from date: Date) -> Data {
        let now = Int32(Date().timeIntervalSince1970)
        let from = Int32(date.timeIntervalSince1970)
        let nowData = withUnsafeBytes(of: now) { Data($0) }
        let fromData = withUnsafeBytes(of: from) { Data($0) }
        var data = Data()
        data.append(0x30)
        data.append(0x30)
        data.append(0x11)
        data.append(nowData)
        data.append(fromData)
        return data
    }
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
