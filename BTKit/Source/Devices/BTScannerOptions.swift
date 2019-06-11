import Foundation

extension Array where Element == BTScannerOptionsInfoItem {
    static let empty: BTScannerOptionsInfo = []
}

public typealias BTScannerOptionsInfo = [BTScannerOptionsInfoItem]

public enum BTScannerOptionsInfoItem {
    case callbackQueue(CallbackQueue)
}

public struct BTKitParsedOptionsInfo {
    public var callbackQueue: CallbackQueue = .mainCurrentOrAsync
    
    public init(_ info: BTScannerOptionsInfo?) {
        guard let info = info else { return }
        for option in info {
            switch option {
            case .callbackQueue(let value): callbackQueue = value
            }
        }
    }
}
