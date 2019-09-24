import Foundation

public enum BTError: Error {
    case logic(BTLogicError)
    case unexpected(BTUnexpectedError)
}

public enum BTUnexpectedError: Error {
    case characteristicIsNil
    case dataIsNil
}

extension BTError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .logic(let error):
            return error.localizedDescription
        case .unexpected(let error):
            return error.localizedDescription
        }
    }
}

public enum BTLogicError: Error {
    case notConnected
    case notConnectable
}

extension BTLogicError: LocalizedError {
    public var errorDescription: String? {
        var bundle: Bundle = .main
        if let path = Bundle(for: BundleClass.self).path(forResource: "BTKit", ofType: "bundle") {
            bundle = Bundle(path: path) ?? Bundle.main
        }
        switch self {
        case .notConnected:
            return NSLocalizedString("BTLogicError.notConnected", bundle: bundle, comment: "")
        case .notConnectable:
            return NSLocalizedString("BTLogicError.notConnectable", bundle: bundle, comment: "")
        }
    }
}

private class BundleClass {}
