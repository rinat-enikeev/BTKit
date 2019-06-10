public struct BTKit {   
    static var scanner: BTScanner {
        return BTScanneriOS(decoders: [RuuviDecoderiOS()])
    }
}
