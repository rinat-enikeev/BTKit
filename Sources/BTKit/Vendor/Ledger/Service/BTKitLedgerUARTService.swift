import Foundation

#if compiler(>=5.5) && canImport(_Concurrency)
@available(macOS 10.15, iOS 13, watchOS 6, tvOS 13, *)
extension BTKitLedgerUARTService {
    public func first<T: AnyObject>(_ observer: T, timeout: TimeInterval = 10) async throws -> LedgerNanoX {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<LedgerNanoX, Error>) in
            let requestTimeInterval = Date().timeIntervalSince1970
            var token: ObservationToken?
            token = BTKit.foreground.scan(observer) { observer, device in
                guard token != nil else { return }
                guard Date().timeIntervalSince1970 - requestTimeInterval < timeout else {
                    token?.invalidate()
                    token = nil
                    continuation.resume(throwing: BTLogicError.serviceTimedOut)
                    return
                }
                if case let .ledger(ledgerDevice) = device {
                    switch ledgerDevice {
                    case let .nanoX(ledgerNanoX):
                        token?.invalidate()
                        token = nil
                        continuation.resume(returning: ledgerNanoX)
                    }
                }
            }
        }
    }
}
#endif

public struct BTKitLedgerUARTService {
    public func fetchAddress<T: AnyObject>(
        _ observer: T,
        _ uuid: String,
        _ options: BTScannerOptionsInfo?,
        path: String,
        _ verify: Bool,
        progress: ((BTServiceProgress) -> Void)? = nil,
        _ result: @escaping (T, Result<LedgerAddressResult, BTError>
    ) -> Void) {
        var connectToken: ObservationToken?
        progress?(.connecting)
        connectToken = BTKit.background.connect(for: observer, uuid: uuid, options: options, connected: { (observer, connectResult) in
            connectToken?.invalidate()
            switch connectResult {
            case .already:
                var serveToken: ObservationToken?
                progress?(.serving)
                serveToken = self.serveLedgerAddress(observer, uuid, options, path: path, verify) { observer, serveResult in
                    var disconnectToken: ObservationToken?
                    switch serveResult {
                    case .success:
                        serveToken?.invalidate()
                        progress?(.disconnecting)
                        disconnectToken = BTKit.background.disconnect(for: observer, uuid: uuid, options: options) { (observer, disconnectResult) in
                            disconnectToken?.invalidate()
                            switch disconnectResult {
                            case .already:
                                progress?(.success)
                                result(observer, serveResult)
                            case .just:
                                progress?(.success)
                                result(observer, serveResult)
                            case .stillConnected:
                                result(observer, serveResult)
                                progress?(.success)
                            case .bluetoothWasPoweredOff:
                                progress?(.success)
                                result(observer, serveResult)
                            case .failure(let error):
                                progress?(.failure(error))
                                result(observer, .failure(error))
                            }
                        }
                    case .failure(let error):
                        progress?(.failure(error))
                        result(observer, .failure(error))
                    }

                }
            case .just:
                var serveToken: ObservationToken?
                progress?(.serving)
                serveToken = self.serveLedgerAddress(observer, uuid, options, path: path, verify) { observer, serveResult in
                    switch serveResult {
                    case .success:
                        serveToken?.invalidate()
                        var disconnectToken: ObservationToken?
                        progress?(.disconnecting)
                        disconnectToken = BTKit.background.disconnect(for: observer, uuid: uuid, options: options) { (observer, disconnectResult) in
                            disconnectToken?.invalidate()
                            switch disconnectResult {
                            case .already:
                                progress?(.success)
                                result(observer, serveResult)
                            case .just:
                                progress?(.success)
                                result(observer, serveResult)
                            case .stillConnected:
                                progress?(.success)
                                result(observer, serveResult)
                            case .bluetoothWasPoweredOff:
                                progress?(.success)
                                result(observer, serveResult)
                            case .failure(let error):
                                progress?(.failure(error))
                                result(observer, .failure(error))
                            }
                        }
                    case .failure(let error):
                        progress?(.failure(error))
                        result(observer, .failure(error))
                    }
                }
            case .failure(let error):
                progress?(.failure(error))
                result(observer, .failure(error))
            case .disconnected:
                break // do nothing, it will reconnect
            }
        })
    }

    private func serveLedgerAddress<T: AnyObject>(_ observer: T, _ uuid: String, _ options: BTScannerOptionsInfo?, path: String, _ verify: Bool, _ result: @escaping (T, Result<LedgerAddressResult, BTError>) -> Void) -> ObservationToken? {
        let service: LedgerServiceType = .address
        guard let requestData = service.requestAddress(path: path, verify: verify) else {
            result(observer, .failure(.unexpected(.failedToParseRequest)))
            return nil
        }
        let info = BTKitParsedOptionsInfo(options)
        let serveToken = BTKit.background.scanner.serveLedger(
            observer,
            for: uuid,
            .ledger(service),
            options: options,
            request: { (observer, peripheral, rx, tx) in
                if let rx = rx {
                    peripheral?.writeValue(requestData, for: rx, type: .withResponse)
                } else {
                    info.callbackQueue.execute {
                        result(observer, .failure(.unexpected(.characteristicIsNil)))
                    }
                }

            }, response: { (observer, data, finished) in
                guard let data = data else {
                    info.callbackQueue.execute {
                        result(observer, .failure(.unexpected(.dataIsNil)))
                    }
                    return
                }
                guard let ledgerAddress = service.decodeAddress(data: data) else {
                    info.callbackQueue.execute {
                        result(observer, .failure(.unexpected(.failedToParseResponse)))
                    }
                    return
                }
                info.callbackQueue.execute {
                    finished?(true)
                    result(observer, .success(ledgerAddress))
                }
            }) { (observer, error) in
                info.callbackQueue.execute {
                    result(observer, .failure(error))
                }
            }
        return serveToken
    }
}
