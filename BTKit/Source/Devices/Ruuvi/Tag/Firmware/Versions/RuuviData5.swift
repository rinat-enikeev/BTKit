public struct RuuviData5 {
    public var uuid: String
    public var rssi: Int
    public var isConnectable: Bool
    public var version: Int
    public var humidity: Double?
    public var temperature: Double?
    public var pressure: Double?
    public var accelerationX: Double?
    public var accelerationY: Double?
    public var accelerationZ: Double?
    public var voltage: Double?
    public var movementCounter: Int?
    public var measurementSequenceNumber: Int?
    public var txPower: Int?
    public var mac: String
}
