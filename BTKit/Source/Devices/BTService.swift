import Foundation
import CoreBluetooth

public enum BTServiceType {
    case ruuvi(BTRuuviServiceType)
    
    var uuid: CBUUID {
        switch self {
        case .ruuvi(let type):
            switch type {
            case .uart(let service):
                return service.uuid
            }
        }
    }
}

public enum BTRuuviNUSService {
    case temperature // in °C
    case humidity // relative
    case pressure // in hPa
    case all
    
    var uuid: CBUUID {
        return CBUUID(string: "6E400001-B5A3-F393-E0A9-E50E24DCCA9E")
    }
    
    var flag: UInt8 {
        switch self {
        case .temperature:
            return 0x30
        case .humidity:
            return 0x31
        case .pressure:
            return 0x32
        case .all:
            return 0x3A
        }
    }
    
    var multiplier: Double {
        switch self {
        case .temperature:
            return 0.01
        case .humidity:
            return 0.01
        case .pressure:
            return 0.01
        case .all:
            return 0.01
        }
    }
    
    func request(from date: Date) -> Data {
        let nowTI = Date().timeIntervalSince1970
        var now = UInt32(nowTI)
        now = UInt32(bigEndian: now)
        let fromTI = date.timeIntervalSince1970
        var from = UInt32(fromTI)
        from = UInt32(bigEndian: from)
        let nowData = withUnsafeBytes(of: now) { Data($0) }
        let fromData = withUnsafeBytes(of: from) { Data($0) }
        var data = Data()
        data.append(flag)
        data.append(0x30)
        data.append(0x11)
        data.append(nowData)
        data.append(fromData)
        return data
    }
    
    func response(from data: Data) -> (Date,Double)? {
        guard data.count == 11 else { return nil }
        guard data[1] == flag else { return nil }
        let timestampData = data[3...6]
        var timestamp: UInt32 = 0
        let timestampBytesCopied = withUnsafeMutableBytes(of: &timestamp, { timestampData.copyBytes(to: $0)} )
        timestamp = UInt32(bigEndian: timestamp)
        assert(timestampBytesCopied == MemoryLayout.size(ofValue: timestamp))
        
        let valueData = data[7...10]
        var value: Int32 = 0
        let valueBytesCopied = withUnsafeMutableBytes(of: &value, { valueData.copyBytes(to: $0) })
        assert(valueBytesCopied == MemoryLayout.size(ofValue: value))
        
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        value = Int32(bigEndian: value)
        return (date, Double(value) * multiplier)
    }
    
    func isEndOfTransmissionFlag(data: Data) -> Bool {
        guard data.count == 11 else { return false }
        let payload = data[3...10]
        var value: UInt64 = 0
        let bytesCopied = withUnsafeMutableBytes(of: &value, { payload.copyBytes(to: $0)} )
        assert(bytesCopied == MemoryLayout.size(ofValue: value))
        return value == UInt64.max
    }
}

public enum BTRuuviServiceType {
    case uart(BTRuuviNUSService)
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
