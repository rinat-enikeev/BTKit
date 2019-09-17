# BTKit
> Access Ruuvi BLE devices with dot syntax: device.ruuvi?.tag

[![Swift Version][swift-image]][swift-url]
[![License][license-image]][license-url]
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat-square)](http://makeapullrequest.com)

Scan for Ruuvi BLE devices and access them with dot syntax. See [tutorial](https://medium.com/btkit-swift-framework-for-ble/tutorial-ios-ruuvitag-listener-f55952b49c6a). 

## Features

- [x] Listen to [RuuviTag](https://ruuvi.com/index.php?id=2) data
- [x] Connect/disconnect [RuuviTag](https://ruuvi.com/index.php?id=2) 
- [x] Read [RuuviTag](https://ruuvi.com/index.php?id=2) logs 

## Requirements

- iOS 10.0+
- Xcode 10.2.1+

## Installation

#### CocoaPods
You can use [CocoaPods](http://cocoapods.org/) to install `BTKit` by adding it to your `Podfile`:

```ruby
platform :ios, '10.0'
use_frameworks!
pod 'BTKit'
```

## Usage example

To make it work import `BTKit` 

``` swift
import BTKit
```

### Check for Bluetooth state

```swift
view.isBluetoothEnabled = scanner.bluetoothState == .poweredOn

BTKit.scanner.state(self, closure: { (observer, state) in
    observer.view.isBluetoothEnabled = state == .poweredOn
})
```

### Listen to broadcasts

```swift
BTKit.scanner.scan(self) { (observer, device) in
                             if let ruuviTag = device.ruuvi?.tag {
                                 print(ruuviTag)
                             }
                         }
```

### Determine if device is out of range or went offline

```swift
BTKit.scanner.lost(self, options: [.lostDeviceDelay(10)], closure: { (observer, device) in
    if let ruuviTag = device.ruuvi?.tag {
        print("Ruuvi Tag " + ruuviTag + " didn't broadcast for 10 seconds")
    }
})
```

### Observe specific device

```swift
BTKit.scanner.observe(self, uuid: ruuviTag.uuid, options: [.callbackQueue(.untouch)]) { (observer, device) in
    print("New device broadcast" + device)
}
```

### Connect to specific device

```swift
if ruuviTag.isConnectable {
    ruuviTag.connect(for: self) { (observer, result) in
        switch result {
        case .already:
            print("already connected")
        case .just:
            print("just connected")
        case .disconnected:
            print("just disconnected")
        case .failure(let error):
            print(error.localizedDescription)
        }
    }
}
```
or use `uuid` 

```swift
BTKit.connection.establish(for: self, uuid: ruuviTag.uuid) { (observer, result) in
    switch result {
    case .already:
        observer.isConnected = true
    case .just:
        observer.isConnected = true
    case .disconnected:
        observer.isConnected = false
    case .failure(let error):
        print(error.localizedDescription)
        observer.isConnected = false
    }
}
```

### Read temperature, humidity, pressure logs from the connectable device

```swift
if let from = Calendar.current.date(byAdding: .minute, value: -5, to: Date()) {
    ruuviTag.celisus(for: self, from: from) { (observer, result) in
        switch result {
        case .success(let values):
            print(values)
        case .failure(let error):
            print(error.localizedDescription)
        }
    }
    ruuviTag.humidity(for: self, from: from) { (observer, result) in
        switch result {
        case .success(let values):
            print(values)   
        case .failure(let error):
            print(error.localizedDescription)
        }
    }
    ruuviTag.pressure(for: self, from: from) { (observer, result) in
        switch result {
        case .success(let values):
            print(values)
        case .failure(let error):
            print(error.localizedDescription)
        }
    }
}
```

or use `BTKit` if you know only the `uuid`:

```swift
BTKit.service.ruuvi.uart.nus.celisus(for: self, uuid: ruuviTag.uuid, from: from, result: { (observer, result) in
    switch result {
    case .success(let values):
        print(values)
    case .failure(let error):
        print(error.localizedDescription)
    }
})

BTKit.service.ruuvi.uart.nus.humidity(for: self, uuid: ruuviTag.uuid, from: from, result: { (observer, result) in
    switch result {
    case .success(let values):
        print(values)
    case .failure(let error):
        print(error.localizedDescription)
    }
})

BTKit.service.ruuvi.uart.nus.pressure(for: self, uuid: ruuviTag.uuid, from: from, result: { (observer, result) in
    switch result {
    case .success(let values):
        print(values)
    case .failure(let error):
        print(error.localizedDescription)
    }
})
```

### Read full log in one batch

```swift
if let from = Calendar.current.date(byAdding: .minute, value: -5, to: Date()) {
    ruuviTag.log(for: self, from: from) { (observer, result) in
        switch result {
        case .success(let logs):
            print(logs)
        case .failure(let error):
            print(error.localizedDescription)
        }
    }
}
```

Or use `BTKit` if you know only the `uuid`

```swift
BTKit.service.ruuvi.uart.nus.log(for: self, uuid: ruuviTag.uuid, from: from, result: { (observer, result) in
    switch result {
    case .success(let logs):
        print(logs)
    case .failure(let error):
        print(error.localizedDescription)
    }
})
```

### Disconnect from the device

```swift
ruuviTag.disconnect(for: self) { (observer, result) in
    switch result {
    case .just:
        observer.isConnected = false
    case .already:
        observer.isConnected = false
    case .failure(let error):
        observer.isConnected = false
        print(error.localizedDescription)
    }
}
```

or use `BTKit` if you know only `uuid`

```swift
BTKit.connection.drop(for: self, uuid: ruuviTag.uuid) { (observer, result) in
    switch result {
    case .just:
        observer.isConnected = false
    case .already:
        observer.isConnected = false
    case .failure(let error):
        observer.isConnected = false
        print(error.localizedDescription)
    }
}
```

## Contribute

We would love you for the contribution to **BTKit**, check the ``LICENSE`` file for more info.

## Meta

Rinat Enikeev – rinat.enikeev@gmail.com

Distributed under the BSD license. See ``LICENSE`` for more information.

[swift-image]:https://img.shields.io/badge/swift-5.0-orange.svg
[swift-url]: https://swift.org/
[license-image]: https://img.shields.io/badge/License-BSD-blue.svg
[license-url]: LICENSE
