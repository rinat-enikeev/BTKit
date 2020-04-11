public struct Ruuvi: BTVendor {
    public static let eddystone = "ruu.vi/#"
    public static let vendorId = 0x0499
    public static let decoder: BTDecoder = RuuviDecoderiOS()
}
