// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BubblyContacts",
    platforms: [.iOS(.v26)],
    products: [
        .library(
            name: "BubblyContacts",
            targets: ["BubblyContacts"]
        )
    ],
    dependencies: [
        .package(name: "Services", path: "../Services")
    ],
    targets: [
        .target(
            name: "BubblyContacts",
            dependencies: [
                .product(name: "Services", package: "Services")
            ]
        ),
        .testTarget(
            name: "BubblyContactsTests",
            dependencies: [
                "BubblyContacts"
            ]
        ),
    ]
)
