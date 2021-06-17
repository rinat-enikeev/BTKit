// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BTKit",
    platforms: [
       .macOS(.v10_13), .iOS(.v10),
    ],
    products: [
        .library(
            name: "BTKit",
            targets: ["BTKit"]),
    ],
    targets: [
        .target(
            name: "BTKit",
            dependencies: [])
    ]
)
