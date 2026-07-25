// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BubblyContacts",
    platforms: [.iOS(.v26)],
    products: [
        .library(
            name: "BubblyContacts",
            targets: ["BubblyContacts"],
        ),
    ],
    dependencies: [
        .package(name: "Core", path: "../Core"),
        .package(name: "Database", path: "../Database"),
        .package(name: "Services", path: "../Services"),
        .package(name: "XUI", path: "../XUI"),
        .package(name: "ImageLoader", path: "../ImageLoader"),
    ],
    targets: [
        .target(
            name: "BubblyContacts",
            dependencies: [
                .product(name: "Core", package: "Core"),
                .product(name: "Database", package: "Database"),
                .product(name: "Services", package: "Services"),
                .product(name: "XUI", package: "XUI"),
                .product(name: "ImageLoader", package: "ImageLoader"),
            ],
        ),
        .testTarget(
            name: "BubblyContactsTests",
            dependencies: [
                "BubblyContacts",
                .product(name: "Database", package: "Database"),
            ],
        ),
    ],
)
