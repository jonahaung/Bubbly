// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "XUI",
    platforms: [
        .iOS(.v26),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "XUI",
            targets: ["XUI"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/SFSafeSymbols/SFSafeSymbols.git",
            .upToNextMajor(from: "5.3.0")
        ),
        .package(name: "Anima", path: "../Anima")
    ],
    targets: [
        .target(
            name: "XUI",
            dependencies: [
                .product(name: "SFSafeSymbols", package: "SFSafeSymbols"),
                .product(name: "Anima", package: "Anima")
            ],
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "XUITests",
            dependencies: ["XUI"]
        )
    ]
)
