public enum BTDevice {
    case ruuvi(RuuviDevice)
    case unknown(BTUnknownDevice)
}

public struct BTUnknownDevice {
    public var uuid: String
    public var rssi: Int
    public var isConnectable: Bool
    public var name: String?
}

public extension BTUnknownDevice {
    var isConnected: Bool {
        return BTKit.scanner.isConnected(uuid: uuid)
    }
}

public extension BTDevice {
    var ruuvi: RuuviDevice? {
        if case let .ruuvi(device) = self {
            return device
        } else {
            return nil
        }
    }
    
    var uuid: String {
        switch self {
        case .ruuvi(let ruuviDevice):
            switch ruuviDevice {
            case .tag(let ruuviTag):
                return ruuviTag.uuid
            }
        case .unknown(let unknownDevice):
            return unknownDevice.uuid
        }
    }
    
    var rssi: Int {
        switch self {
        case .ruuvi(let ruuviDevice):
            switch ruuviDevice {
            case .tag(let ruuviTag):
                return ruuviTag.rssi
            }
        case .unknown(let unknownDevice):
            return unknownDevice.rssi
        }
    }
    
    var isConnectable: Bool {
        switch self {
        case .ruuvi(let ruuviDevice):
            switch ruuviDevice {
            case .tag(let ruuviTag):
                return ruuviTag.isConnectable
            }
        case .unknown(let unknownDevice):
            return unknownDevice.isConnectable
        }
    }
}

extension BTDevice: Hashable {
    public func hash(into hasher: inout Hasher) {
        let key = uuid
        hasher.combine(key)
    }
}

extension BTDevice: Equatable {
    public static func ==(lhs: BTDevice, rhs: BTDevice) -> Bool {
        return lhs.uuid == rhs.uuid
    }
}

extension BTUnknownDevice: Hashable {
    public func hash(into hasher: inout Hasher) {
        let key = uuid
        hasher.combine(key)
    }
}

extension BTUnknownDevice: Equatable {
    public static func ==(lhs: BTUnknownDevice, rhs: BTUnknownDevice) -> Bool {
        return lhs.uuid == rhs.uuid
    }
}
