// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Services",
    platforms: [
        .iOS(.v26),
        .macOS(.v12),
    ],
    products: [
        .library(
            name: "Services",
            targets: ["Services"],
        ),
    ],
    dependencies: [
        .package(name: "Database", path: "../Database"),
    ],
    targets: [
        .target(
            name: "Services",
            dependencies: [
                .product(name: "Database", package: "Database"),
            ],
            exclude: [
                "Package.swift",
            ],
        ),
        .testTarget(
            name: "ServicesTests",
            dependencies: ["Services"],
        ),
    ],
)
