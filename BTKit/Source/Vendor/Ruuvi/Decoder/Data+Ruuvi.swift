import Foundation

public extension Ruuvi {
    struct Data2 {
        var version: Int
        var humidity: Double
        var temperature: Double
        var pressure: Double
    }

    struct Data3 {
        var humidity: Double
        var temperature: Double
        var pressure: Double
        var accelerationX: Double
        var accelerationY: Double
        var accelerationZ: Double
        var voltage: Double
    }

    struct Data4 {
        var version: Int
        var humidity: Double
        var temperature: Double
        var pressure: Double
    }

    struct Data5 {
        var humidity: Double?
        var temperature: Double?
        var pressure: Double?
        var accelerationX: Double?
        var accelerationY: Double?
        var accelerationZ: Double?
        var movementCounter: Int?
        var measurementSequenceNumber: Int?
        var voltage: Double?
        var txPower: Int?
        var mac: String
    }
}

infix operator >>> : BitwiseShiftPrecedence

func >>> (lhs: UInt32, rhs: UInt32) -> UInt32 {
    return UInt32(bitPattern: Int32(UInt64(bitPattern: Int64(lhs)) >> UInt64(rhs)))
}

public extension Data {
    
    func ruuvi2() -> Ruuvi.Data2 {
        let version = Int(self[0])
        let humidity = ((Double) (self[1] & 0xFF)) / 2.0
        let uTemp = Double((UInt16(self[2] & 127) << 8) | UInt16(self[3]))
        let tempSign = UInt16(self[2] >> 7) & UInt16(1)
        let temperature = tempSign == 0 ? uTemp / 256.0 : -1.00 * uTemp / 256.0
        let pressure = (Double(((UInt16(self[4]) << 8) + UInt16(self[5]))) + 50000) / 100.0
        return Ruuvi.Data2(version: version, humidity: humidity, temperature: temperature, pressure: pressure)
    }
    
    func ruuvi3() -> Ruuvi.Data3 {
        let humidity = Double(self[3]) * 0.5
        
        let temperatureSign = (self[4] >> 7) & 1
        let temperatureBase = self[4] & 0x7F
        let temperatureFraction = Double(self[5]) / 100.0
        var temperature = Double(temperatureBase) + temperatureFraction
        if (temperatureSign == 1) {
            temperature *= -1
        }
        
        let pressureHi = self[6] & 0xFF
        let pressureLo = self[7] & 0xFF
        let pressure = (Double(pressureHi) * 256.0 + 50000.0 + Double(pressureLo)) / 100.0
        
        let accelerationX = Double(self[8...9].withUnsafeBytes({ $0.bindMemory(to: Int16.self) }).map(Int16.init(bigEndian:)).first ?? 0) / 1000.0
        let accelerationY = Double(self[10...11].withUnsafeBytes({ $0.bindMemory(to: Int16.self) }).map(Int16.init(bigEndian:)).first ?? 0) / 1000.0
        let accelerationZ = Double(self[12...13].withUnsafeBytes({ $0.bindMemory(to: Int16.self) }).map(Int16.init(bigEndian:)).first ?? 0) / 1000.0
        
        let battHi = self[14] & 0xFF
        let battLo = self[15] & 0xFF
        let voltage = (Double(battHi) * 256.0 + Double(battLo)) / 1000.0
        return Ruuvi.Data3(humidity: humidity, temperature: temperature, pressure: pressure, accelerationX: accelerationX, accelerationY: accelerationY, accelerationZ: accelerationZ, voltage: voltage)
    }
    
    func ruuvi4() -> Ruuvi.Data4 {
        let version = Int(self[0])
        let humidity = ((Double) (self[1] & 0xFF)) / 2.0
        let uTemp = Double((UInt16(self[2] & 127) << 8) | UInt16(self[3]))
        let tempSign = UInt16(self[2] >> 7) & UInt16(1)
        let temperature = tempSign == 0 ? uTemp / 256.0 : -1.00 * uTemp / 256.0
        let pressure = (Double(((UInt16(self[4]) << 8) + UInt16(self[5]))) + 50000) / 100.0
        return Ruuvi.Data4(version: version, humidity: humidity, temperature: temperature, pressure: pressure)
    }
    
    func ruuvi5() -> Ruuvi.Data5 {
        
        var temperature = Double(UInt16(self[3]) << 8 | UInt16(self[4] & 0xFF))
        if temperature > 32767 {
            temperature -= 65534
        }
        temperature /= 200.0
        
        
        
        let humidity = Double(UInt16(self[5] & 0xFF) << 8 | UInt16(self[6] & 0xFF)) / 400.0
        
        var pressure = Double(UInt16(self[7] & 0xFF) << 8 | UInt16(self[8] & 0xFF)) + 50000
        pressure /= 100.0
        
        let accelerationX = Double(self[9...10].withUnsafeBytes({ $0.bindMemory(to: Int16.self) }).map(Int16.init(bigEndian:)).first ?? 0) / 1000.0
        let accelerationY = Double(self[11...12].withUnsafeBytes({ $0.bindMemory(to: Int16.self) }).map(Int16.init(bigEndian:)).first ?? 0) / 1000.0
        let accelerationZ = Double(self[13...14].withUnsafeBytes({ $0.bindMemory(to: Int16.self) }).map(Int16.init(bigEndian:)).first ?? 0) / 1000.0
        
        let powerInfo = UInt32(UInt16(self[15] & 0xFF) << 8 | UInt16(self[16] & 0xFF))
        var voltage: Double = 0
        if ((powerInfo >>> UInt32(5)) != 0b11111111111) {
            voltage = Double(powerInfo >>> UInt32(5)) / 1000.0 + 1.6
            voltage = (voltage*1000).rounded()/1000
        }
        var txPower = 0
        if ((powerInfo & 0b11111) != 0b11111) {
            txPower = Int((powerInfo & 0b11111) * 2 - 40)
        }
        let movementCounter = Int(self[18] & 0xFF)
        let measurementSequenceNumber = Int(UInt16(self[20] & 0xFF) << 8 | UInt16(self[19] & 0xFF))
        
        let asStr = self.hexEncodedString()
        let start = asStr.index(asStr.endIndex, offsetBy: -12)
        let mac = addColons(mac: String(asStr[start...]))
        return Ruuvi.Data5(humidity: humidity, temperature: temperature, pressure: pressure, accelerationX: accelerationX, accelerationY: accelerationY, accelerationZ: accelerationZ, movementCounter: movementCounter, measurementSequenceNumber: measurementSequenceNumber, voltage: voltage, txPower: txPower, mac: mac)
        
    }
    
    private struct HexEncodingOptions: OptionSet {
        let rawValue: Int
        static let upperCase = HexEncodingOptions(rawValue: 1 << 0)
    }
    
    private func hexEncodedString(options: HexEncodingOptions = []) -> String {
        let format = options.contains(.upperCase) ? "%02hhX" : "%02hhx"
        return map { String(format: format, $0) }.joined()
    }
    
    private func addColons(mac: String) -> String {
        let out = NSMutableString(string: mac)
        var i = mac.count - 2
        while (i > 0) {
            out.insert(":", at: i)
            i -= 2
        }
        return out.uppercased as String
    }
}
