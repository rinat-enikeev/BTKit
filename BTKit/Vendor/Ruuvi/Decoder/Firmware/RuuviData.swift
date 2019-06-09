public protocol RuuviData: BTData {
    var uuid: String { get }
    var rssi: Int { get }
    var version: Int { get }
    var temperature: Double { get }
    var humidity: Double { get }
    var pressure: Double { get }
}
