import Foundation

public enum LedgerDevice {
    case nanoX(LedgerNanoX)
}

public struct LedgerNanoX: Hashable {
    public var uuid: String
    public var name: String?
    public var rssi: Int?
    public var isConnectable: Bool

    public init(
        uuid: String,
        name: String?,
        rssi: Int?,
        isConnectable: Bool
    ) {
        self.uuid = uuid
        self.name = name
        self.rssi = rssi
        self.isConnectable = isConnectable
    }
}

public extension LedgerNanoX {
    func address<T: AnyObject>(for observer: T, options: BTScannerOptionsInfo? = nil, path: String, verify: Bool, result: @escaping (T, Result<LedgerAddressResult, BTError>) -> Void) {

    }

}

#if compiler(>=5.5) && canImport(_Concurrency)

@available(macOS 10.15, iOS 13, watchOS 6, tvOS 13, *)
extension LedgerNanoX {
    public func address<T: AnyObject>(
        _ observer: T,
        path: String = "44'/60'/0'/0/0",
        verify: Bool = false,
        options: BTScannerOptionsInfo? = [.connectionTimeout(1), .serviceTimeout(1)]
    ) async throws -> LedgerAddressResult {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<LedgerAddressResult, Error>) in
            if !isConnectable {
                continuation.resume(throwing: BTLogicError.notConnectable)
            } else {
                var alreadyCalled = false
                BTKit.background.services.ledger.fetchAddress(observer, uuid, options, path: path, verify) { observer, result in
                    guard !alreadyCalled else { return }
                    alreadyCalled = true
                    switch result {
                    case let .success(addressResult):
                        continuation.resume(returning: addressResult)
                    case let .failure(error):
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }
}
#endif

