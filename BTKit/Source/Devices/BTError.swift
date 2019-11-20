import Foundation

public enum BTError: Error {
    case logic(BTLogicError)
    case connect(Error)
    case readRSSI(Error)
    case unexpected(BTUnexpectedError)
}

public enum BTUnexpectedError: Error {
    case characteristicIsNil
    case dataIsNil
    case bothResultAndErrorAreNil
}

extension BTError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .logic(let error):
            return error.localizedDescription
        case .connect(let error):
            return error.localizedDescription
        case .readRSSI(let error):
            return error.localizedDescription
        case .unexpected(let error):
            return error.localizedDescription
        }
    }
}

public enum BTLogicError: Error {
    case notConnected
    case notConnectable
    case connectedByOthers
    case connectionTimedOut
    case serviceTimedOut
    case bluetoothWasPoweredOff
}

extension BTLogicError: LocalizedError {
    public var errorDescription: String? {
        var bundle: Bundle = .main
        if let path = Bundle(for: BundleClass.self).path(forResource: "BTKit", ofType: "bundle") {
            bundle = Bundle(path: path) ?? Bundle.main
        }
        switch self {
        case .serviceTimedOut:
            return NSLocalizedString("BTLogicError.serviceTimedOut", bundle: bundle, comment: "")
        case .notConnected:
            return NSLocalizedString("BTLogicError.notConnected", bundle: bundle, comment: "")
        case .notConnectable:
            return NSLocalizedString("BTLogicError.notConnectable", bundle: bundle, comment: "")
        case .connectedByOthers:
            return NSLocalizedString("BTLogicError.connectedByOthers", bundle: bundle, comment: "")
        case .connectionTimedOut:
            return NSLocalizedString("BTLogicError.connectionTimedOut", bundle: bundle, comment: "")
        case .bluetoothWasPoweredOff:
            return NSLocalizedString("BTLogicError.bluetoothWasPoweredOff", bundle: bundle, comment: "")
        }
    }
}

private class BundleClass {}
