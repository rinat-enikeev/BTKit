import Foundation

public enum BTError: Error {
    case service(BTServiceError)
    case unexpected(BTUnexpectedError)
}

public enum BTUnexpectedError: Error {
    case characteristicIsNil
    case dataIsNil
}

public enum BTServiceError: Error {
    case unsupported
}
