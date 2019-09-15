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
}

extension BTLogicError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .notConnected:
            return NSLocalizedString("BTLogicError.notConnected", tableName: nil, bundle: Bundle(for: BundleClass.self), value: "", comment: "")
        }
    }
}

private class BundleClass {}
