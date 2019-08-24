import Foundation

extension Array where Element == BTScannerOptionsInfoItem {
    static let empty: BTScannerOptionsInfo = []
}

public typealias BTScannerOptionsInfo = [BTScannerOptionsInfoItem]

public enum BTScannerOptionsInfoItem {
    case callbackQueue(CallbackQueue)
    case lostDeviceDelay(TimeInterval)
    case demo(Int)
}

public struct BTKitParsedOptionsInfo {
    public var callbackQueue: CallbackQueue = .mainCurrentOrAsync
    public var lostDeviceDelay: TimeInterval = 5
    public var demoCount: Int = 0
    
    public init(_ info: BTScannerOptionsInfo?) {
        guard let info = info else { return }
        for option in info {
            switch option {
            case .callbackQueue(let value): callbackQueue = value
            case .lostDeviceDelay(let value): lostDeviceDelay = value
            case .demo(let value): demoCount = value
            }
        }
    }
}
