public enum BTDevice {
    case ruuvi(RuuviDevice)
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
        }
    }
    
    var rssi: Int {
        switch self {
        case .ruuvi(let ruuviDevice):
            switch ruuviDevice {
            case .tag(let ruuviTag):
                return ruuviTag.rssi
            }
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
