public struct RuuviData4 {
    public var uuid: String
    public var rssi: Int
    public var isConnectable: Bool
    public var version: Int
    public var temperature: Double
    public var humidity: Double
    public var pressure: Double

    public init(uuid: String,
                rssi: Int,
                isConnectable: Bool,
                version: Int,
                temperature: Double,
                humidity: Double,
                pressure: Double) {
        self.uuid = uuid
        self.rssi = rssi
        self.isConnectable = isConnectable
        self.version = version
        self.temperature = temperature
        self.humidity = humidity
        self.pressure = pressure
    }
}
