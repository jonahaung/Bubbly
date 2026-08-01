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
        .package(name: "Core", path: "../Core"),
        .package(name: "Database", path: "../Database"),
        .package(name: "ImageLoader", path: "../ImageLoader"),
        .package(name: "XUI", path: "../XUI"),
        .package(url: "https://github.com/firebase/firebase-ios-sdk", from: "12.4.0"),
    ],
    targets: [
        .target(
            name: "Services",
            dependencies: [
                .product(name: "Core", package: "Core"),
                .product(name: "Database", package: "Database"),
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseMessaging", package: "firebase-ios-sdk"),
                .product(name: "ImageLoader", package: "ImageLoader"),
                .product(name: "XUI", package: "XUI"),
            ],
        ),
        .testTarget(
            name: "ServicesTests",
            dependencies: ["Services"],
        ),
    ],
)
