import Foundation

public enum BTConnectResult {
    case already
    case just
    case disconnected
    case failure(BTError)
}
