# BTKit
> Access Ruuvi BLE devices with dot syntax: device.ruuvi?.tag

[![Swift Version][swift-image]][swift-url]
[![License][license-image]][license-url]
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat-square)](http://makeapullrequest.com)

Scan for Ruuvi BLE devices and access them with dot syntax. See [tutorial](https://medium.com/btkit-swift-framework-for-ble/tutorial-ios-ruuvitag-listener-f55952b49c6a). 

## Features

- [x] Listen to [RuuviTag](https://ruuvi.com/index.php?id=2) advertisements
- [x] Connect/disconnect [RuuviTag](https://ruuvi.com/index.php?id=2) 
- [x] Read [RuuviTag](https://ruuvi.com/index.php?id=2) logs 
- [x] [RuuviTag](https://ruuvi.com/index.php?id=2) logging in background (firmware 3.27.2+) 

## Requirements

- iOS 10.0+
- Xcode 12.0+

## Installation

#### CocoaPods
You can use [CocoaPods](http://cocoapods.org/) to install `BTKit` by adding it to your `Podfile`:

```ruby
platform :ios, '10.0'
use_frameworks!
pod 'BTKit'
```

#### Swift Package Manager

You can add link to this repo in XCode/File/Swift Packages/Add Package Dependency...

## Usage example

To make it work import `BTKit` 

``` swift
import BTKit
```

### Check for iPhone/iPad Bluetooth state

```swift
view.isBluetoothEnabled = scanner.bluetoothState == .poweredOn

BTForeground.shared.state(self, closure: { (observer, state) in
    observer.view.isBluetoothEnabled = state == .poweredOn
})
```

### Listen to advertisements in foreground

```swift
BTForeground.shared.scan(self) { (observer, device) in
                             if let ruuviTag = device.ruuvi?.tag {
                                 print(ruuviTag)
                             }
                         }
```

### Determine if device is out of range or went offline

```swift
BTForeground.shared.lost(self, options: [.lostDeviceDelay(10)], closure: { (observer, device) in
    if let ruuviTag = device.ruuvi?.tag {
        print("Ruuvi Tag is offline or went out of range")
    }
})
```

### Observe specific device advertisements

```swift
BTForeground.shared.observe(self, uuid: ruuviTag.uuid, options: [.callbackQueue(.untouch)]) { (observer, device) in
    print("Specific RuuviTag is advertising")
}
```

### Connect to specific device

```swift
if ruuviTag.isConnectable {
    ruuviTag.connect(for: self, options: [.connectionTimeout(10)],  connected: { observer, result in
        switch result {
        case .just:
            print("just connected")
        case .already:
            print("was already connected")
        case .disconnected:
            print("just disconnected")
        case .failure(let error):
            print(error.localizedDescription)
        }
    }, heartbeat: { observer, device in
        if let ruuviTag = device.ruuvi?.tag {
            print(ruuviTag)
        }
    }, disconnected: { observer, result in
        switch result {
        case .just:
            print("just disconnected")
        case .already:
            print("disconnected")
        case .stillConnected:
            print("still connected because of other callers")
        case .failure(let error):
            print(error.localizedDescription)
        }
    })
}
```
or use `uuid` 

```swift
BTBackground.shared.connect(for: self, options: [.connectionTimeout(10)],  connected: { observer, result in
    switch result {
    case .just:
        print("just connected")
    case .already:
        print("was already connected")
    case .disconnected:
        print("just disconnected")
    case .failure(let error):
        print(error.localizedDescription)
    }
}, heartbeat: { observer, device in
    if let ruuviTag = device.ruuvi?.tag {
        print(ruuviTag)
    }
}, disconnected: { observer, result in
    switch result {
    case .just:
        print("just disconnected")
    case .already:
        print("disconnected")
    case .stillConnected:
        print("still connected because of other callers")
    case .failure(let error):
        print(error.localizedDescription)
    }
})
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
BTBackground.shared.services.ruuvi.nus.celisus(for: self, uuid: ruuviTag.uuid, from: from, result: { (observer, result) in
    switch result {
    case .success(let values):
        print(values)
    case .failure(let error):
        print(error.localizedDescription)
    }
})

BTBackground.shared.services.ruuvi.nus.humidity(for: self, uuid: ruuviTag.uuid, from: from, result: { (observer, result) in
    switch result {
    case .success(let values):
        print(values)
    case .failure(let error):
        print(error.localizedDescription)
    }
})

BTBackground.shared.services.ruuvi.nus.pressure(for: self, uuid: ruuviTag.uuid, from: from, result: { (observer, result) in
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
BTBackground.shared.services.ruuvi.nus.log(for: self, uuid: ruuviTag.uuid, from: from, result: { (observer, result) in
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
    case .stillConnected:
        observer.isConnected = true
    case .failure(let error):
        observer.isConnected = false
        print(error.localizedDescription)
    }
}
```

or use `BTKit` if you know only `uuid`

```swift
BTBackground.shared.disconnect(for: self, uuid: ruuviTag.uuid) { (observer, result) in
    switch result {
    case .just:
        observer.isConnected = false
    case .already:
        observer.isConnected = false
    case .stillConnected:
        observer.isConnected = true
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
