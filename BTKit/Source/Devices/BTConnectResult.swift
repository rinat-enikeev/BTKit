import Foundation

public enum BTConnectResult {
    case already
    case just
    case disconnected // by peripheral
    case failure(BTError)
}

public enum BTDisconnectResult {
    case already
    case just
    case stillConnected // by other objects
    case failure(BTError)
}
