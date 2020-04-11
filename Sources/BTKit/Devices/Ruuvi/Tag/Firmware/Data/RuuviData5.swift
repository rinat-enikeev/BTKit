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

    public init(uuid: String,
                rssi: Int,
                isConnectable: Bool,
                version: Int,
                humidity: Double?,
                temperature: Double?,
                pressure: Double?,
                accelerationX: Double?,
                accelerationY: Double?,
                accelerationZ: Double?,
                voltage: Double?,
                movementCounter: Int?,
                measurementSequenceNumber: Int?,
                txPower: Int?,
                mac: String) {
        self.uuid = uuid
        self.rssi = rssi
        self.isConnectable = isConnectable
        self.version = version
        self.humidity = humidity
        self.temperature = temperature
        self.pressure = pressure
        self.accelerationX = accelerationX
        self.accelerationY = accelerationY
        self.accelerationZ = accelerationZ
        self.voltage = voltage
        self.movementCounter = movementCounter
        self.measurementSequenceNumber = measurementSequenceNumber
        self.txPower = txPower
        self.mac = mac
    }
}
