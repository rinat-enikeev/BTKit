public struct BTForeground {
    public let scanner: BTScanner = BTScanneriOS(decoders: [RuuviDecoderiOS()],
                                                 services: [RuuviNUSService()])
}
