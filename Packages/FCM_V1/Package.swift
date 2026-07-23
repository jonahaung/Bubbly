// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FCM_V1",
    platforms: [.iOS(.v18), .macOS(.v10_15)],
    products: [
        .library(
            name: "FCM_V1",
            targets: ["FCM_V1"]
        )
    ],
    targets: [
        .target(name: "FCM_V1"),
        .testTarget(
            name: "FCM_V1Tests",
            dependencies: ["FCM_V1"]
        )
    ]
)
