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
    
    public static func nusTemperatureHistoryDecode(data: Data) -> (Date,Double)? {
        guard data.count == 11 else { return nil }
        guard data[1] == 0x30 else { return nil }
        guard let timestamp = data[3...6].withUnsafeBytes({ $0.bindMemory(to: UInt32.self) }).map(UInt32.init(bigEndian:)).first else { return nil }
        guard let celsiusFraction = data[7...10].withUnsafeBytes({ $0.bindMemory(to: UInt32.self) }).map(UInt32.init(bigEndian:)).first else { return nil }
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let celsius = Double(celsiusFraction) / 100.0
        return (date,celsius)
    }
    
    public static func nusIsEOF(data: Data) -> Bool {
        // last 8 bytes are ffffffffffffffff
        guard data.count == 11 else { return false }
//        guard let value = data[3...10].withUnsafeBytes({ $0.bindMemory(to: UInt64.self) }).map(UInt64.init(bigEndian:)).first else { return false }
        let payload = data[3...10]
        var value: UInt64 = 0
        let bytesCopied = withUnsafeMutableBytes(of: &value, { payload.copyBytes(to: $0)} )
        assert(bytesCopied == MemoryLayout.size(ofValue: value))
        return value == UInt64.max
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
