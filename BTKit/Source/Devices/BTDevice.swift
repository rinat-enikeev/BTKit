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
