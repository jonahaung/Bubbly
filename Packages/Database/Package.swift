// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Database",
    platforms: [
        .iOS(.v26),
        .macOS(.v12),
    ],
    products: [
        .library(
            name: "Database",
            targets: ["Database"],
        ),
    ],
    dependencies: [
        .package(name: "Core", path: "../Core"),
    ],
    targets: [
        .target(
            name: "Database",
            dependencies: [
                .product(name: "Core", package: "Core"),
            ],
        ),
        .testTarget(
            name: "DatabaseTests",
            dependencies: ["Database"],
        ),
    ],
)
