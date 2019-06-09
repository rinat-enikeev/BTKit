public struct RuuviData2: RuuviData {
    public var uuid: String
    public var rssi: Int
    public var version: Int
    public var temperature: Double
    public var humidity: Double
    public var pressure: Double
}
