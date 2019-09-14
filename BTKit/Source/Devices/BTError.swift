import Foundation

public enum BTError: Error {
    case service(BTServiceError)
}

public enum BTServiceError: Error {
    case unsupported
}
