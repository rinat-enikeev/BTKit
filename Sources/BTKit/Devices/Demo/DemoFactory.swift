import Foundation

struct DemoFactory {
    static let shared = DemoFactory()
    
    func build(for uuid: String) -> BTDevice {
        let rssi = -Int(arc4random_uniform(90))
        let humidity = Double(arc4random_uniform(100))
        let temperature = Double(arc4random_uniform(30))
        let pressure = Double(arc4random_uniform(100)) + 1000.0
        let accelerationX = Double(arc4random_uniform(1000)) / 1000.0
        let accelerationY = Double(arc4random_uniform(1000)) / 1000.0
        let accelerationZ = Double(arc4random_uniform(1000)) / 1000.0
        let voltage = 3.125
        
        return .ruuvi(.tag(.v5(RuuviData5(uuid: uuid,
                                          rssi: rssi,
                                          isConnectable: false,
                                          version: 5,
                                          humidity: humidity,
                                          temperature: temperature,
                                          pressure: pressure,
                                          accelerationX: accelerationX,
                                          accelerationY: accelerationY,
                                          accelerationZ: accelerationZ,
                                          voltage: voltage,
                                          movementCounter: 0,
                                          measurementSequenceNumber: 1,
                                          txPower: 4,
                                          mac: "D0:9D:56:C5:BF:5D"))))
    }
}
