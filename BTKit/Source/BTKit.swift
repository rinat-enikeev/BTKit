public struct BTKit {   
    public static let scanner: BTScanner = BTScanneriOS(decoders: [RuuviDecoderiOS()], services: [RuuviNUSService()])
    
    public static let service: BTKitService = BTKitService()
}

public struct BTKitService {
    public let ruuvi = BTKitRuuviService()
}

public struct BTKitRuuviService {
    public let uart = BTKitRuuviUARTService()
}

public struct BTKitRuuviUARTService {
    public let nus = BTKitRuuviNUSService()
}

public struct BTKitRuuviNUSService {
    public func connect<T: AnyObject>(for observer: T, uuid: String, result: @escaping (T, BTConnectResult) -> Void) -> ObservationToken? {
        if BTKit.scanner.isConnected(uuid: uuid) {
            result(observer, .already)
            return nil
        } else {
            let connectToken = BTKit.scanner.connect(observer, uuid: uuid, connected: { (observer) in
                result(observer, .just)
            }) { (observer) in
                result(observer, .disconnected)
            }
            return connectToken
        }
    }
}
