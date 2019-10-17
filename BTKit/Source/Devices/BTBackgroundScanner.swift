import Foundation

public protocol BTBackgroundScanner {
    func isConnected(uuid: String) -> Bool
    
    @discardableResult
    func connect<T: AnyObject>(_ observer: T, uuid: String,
                               options: BTScannerOptionsInfo?,
                               connected: @escaping (T, BTError?) -> Void,
                               heartbeat: @escaping (T, Data?, BTError?) -> Void,
                               disconnected: @escaping (T, BTError?) -> Void) -> ObservationToken
}

public extension BTBackgroundScanner {
    @discardableResult
    func connect<T: AnyObject>(_ observer: T, uuid: String,
                               connected: @escaping (T, BTError?) -> Void,
                               heartbeat: @escaping (T, Data?, BTError?) -> Void,
                               disconnected: @escaping (T, BTError?) -> Void) -> ObservationToken {
        return connect(observer, uuid: uuid, options: nil, connected: connected, heartbeat: heartbeat, disconnected: disconnected)
    }
}
