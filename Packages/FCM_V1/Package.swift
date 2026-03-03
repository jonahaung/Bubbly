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
    dependencies: [
        .package(url: "https://github.com/Kitura/Swift-JWT.git", from: "4.0.0")
    ],
    targets: [
        .target(
            name: "FCM_V1",
            dependencies: [
                .product(name: "SwiftJWT", package: "Swift-JWT")
            ]
        ),
        .testTarget(
            name: "FCM_V1Tests",
            dependencies: ["FCM_V1"]
        )
    ]
)
