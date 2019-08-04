# BTKit
> Access Ruuvi BLE devices with dot syntax: device.ruuvi?.tag

[![Swift Version][swift-image]][swift-url]
[![License][license-image]][license-url]
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat-square)](http://makeapullrequest.com)

Scan for Ruuvi BLE devices and access them with dot syntax. See [tutorial](https://medium.com/btkit-swift-framework-for-ble/tutorial-ios-ruuvitag-listener-f55952b49c6a). 

## Features

- [x] Listen to [RuuviTag](https://ruuvi.com/index.php?id=2) data

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

To get the full benefits import `BTKit` 

``` swift
import BTKit
```

## Usage example

```swift
import BTKit

BTKit.scanner.scan(self) { (observer, device) in
                             if let ruuviTag = device.ruuvi?.tag {
                                 print(ruuviTag)
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
