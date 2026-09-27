// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "Settings",
    platforms: [.iOS(.v26)],
    products: [
        .library(
            name: "Settings",
            targets: ["Settings"]
        )
    ],
    dependencies: [
        .package(name: "Services", path: "../Services")
    ],
    targets: [
        .target(
            name: "Settings",
            dependencies: [
                .product(name: "Services", package: "Services")
            ]
        ),
        .testTarget(
            name: "SettingsTests",
            dependencies: ["Settings"]
        ),
    ]
)
