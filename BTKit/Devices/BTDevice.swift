public enum BTDevice {
    case ruuviTag(RuuviTag)
}

public extension BTDevice {
    var ruuviTag: RuuviTag? {
        if case let .ruuviTag(ruuviTag) = self {
            return ruuviTag
        } else {
            return nil
        }
    }
}
