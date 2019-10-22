public struct BTKit {   
    public static let scanner: BTScanner = BTScanneriOS(decoders: [RuuviDecoderiOS()], services: [RuuviNUSService()])
    public static let service: BTKitService = BTKitService()
    public static let connection: BTConnection = BTConnection()
    public static let background: BTKitBackground = BTKitBackground()
}
