import CoreBluetooth

public struct RuuviDecoderiOS: BTDecoder {
    public func decode(uuid: String, rssi: NSNumber, advertisementData: [String : Any]) -> BTDevice? {
        if let manufacturerDictionary = advertisementData[CBAdvertisementDataServiceDataKey] as? [NSObject:AnyObject],
            let manufacturerData = manufacturerDictionary.first?.value as? Data {
            guard manufacturerData.count > 18 else { return nil }
            guard let url = String(data: manufacturerData[3 ... manufacturerData.count - 1], encoding: .utf8) else { return nil}
            guard url.starts(with: Ruuvi.eddystone) else { return nil }
            var urlData = url.replacingOccurrences(of: Ruuvi.eddystone, with: "")
            urlData = urlData.padding(toLength: ((urlData.count+3)/4)*4,
                                      withPad: "AAA",
                                      startingAt: 0)
            guard let data = Data(base64Encoded: urlData) else { return nil }
            let version = Int(data[0])
            let isConnectable = (advertisementData[CBAdvertisementDataIsConnectable] as? NSNumber)?.boolValue ?? false
            switch version {
            case 2:
                let ruuvi = data.ruuvi2()
                let tag = RuuviData2(uuid: uuid, rssi: rssi.intValue, isConnectable: isConnectable, version: ruuvi.version, temperature: ruuvi.temperature, humidity: ruuvi.humidity, pressure: ruuvi.pressure)
                return .ruuvi(.tag(.v2(tag)))
            case 4:
                let ruuvi = data.ruuvi4()
                let tag = RuuviData4(uuid: uuid, rssi: rssi.intValue, isConnectable: isConnectable, version: ruuvi.version, temperature: ruuvi.temperature, humidity: ruuvi.humidity, pressure: ruuvi.pressure)
                return .ruuvi(.tag(.v4(tag)))
            default:
                return nil
            }
        } else if let manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data {
            guard manufacturerData.count > 2 else { return nil }
            let manufactureId = UInt16(manufacturerData[0]) + UInt16(manufacturerData[1]) << 8
            guard manufactureId == Ruuvi.vendorId else { return nil }
            let version = manufacturerData[2]
            let isConnectable = (advertisementData[CBAdvertisementDataIsConnectable] as? NSNumber)?.boolValue ?? false
            switch (version) {
            case 3:
                guard manufacturerData.count > 14 else { return nil }
                let ruuvi = manufacturerData.ruuvi3()
                let tag = RuuviData3(uuid: uuid, rssi: rssi.intValue, isConnectable: isConnectable, version: Int(version), humidity: ruuvi.humidity, temperature: ruuvi.temperature, pressure: ruuvi.pressure, accelerationX: ruuvi.accelerationX, accelerationY: ruuvi.accelerationY, accelerationZ: ruuvi.accelerationZ, voltage: ruuvi.voltage)
                return .ruuvi(.tag(.v3(tag)))
            case 5:
                guard manufacturerData.count > 25 else { return nil }
                let ruuvi = manufacturerData.ruuvi5()
                let tag = RuuviData5(uuid: uuid, rssi: rssi.intValue, isConnectable: isConnectable, version: Int(version), humidity: ruuvi.humidity, temperature: ruuvi.temperature, pressure: ruuvi.pressure, accelerationX: ruuvi.accelerationX, accelerationY: ruuvi.accelerationY, accelerationZ: ruuvi.accelerationZ, voltage: ruuvi.voltage, movementCounter: ruuvi.movementCounter, measurementSequenceNumber: ruuvi.measurementSequenceNumber, txPower: ruuvi.txPower, mac: ruuvi.mac)
                return .ruuvi(.tag(.v5(tag)))
            default:
                return nil
            }
        } else {
            return nil
        }
    }
}
