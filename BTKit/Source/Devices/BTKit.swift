public struct BTKit {   
    public static let scanner: BTScanner = BTScanneriOS(decoders: [RuuviDecoderiOS()], services: [RuuviNUSService()])
    public static let service: BTKitService = BTKitService()
    public static let connection: BTKitConnection = BTKitConnection()
    public static let background: BTKitBackground = BTKitBackground()
    
    public static func backgroundScanner(for service: BTService) -> BTBackgroundScanner {
        return BTBackgroundScanneriOS(service: service)
    }
}
