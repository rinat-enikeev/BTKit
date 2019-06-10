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
}
