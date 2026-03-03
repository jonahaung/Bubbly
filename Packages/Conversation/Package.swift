// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "Conversation",
    platforms: [.iOS(.v26)],
    products: [
        .library(
            name: "Conversation",
            targets: ["Conversation"]
        )
    ],
    dependencies: [
        .package(name: "Core", path: "../Core"),
        .package(name: "Database", path: "../Database"),
        .package(name: "Services", path: "../Services"),
        .package(name: "XUI", path: "../XUI"),
        .package(name: "ImageLoader", path: "../ImageLoader"),
        .package(name: "MediaPicker", path: "../MediaPicker"),
        .package(
            url: "https://github.com/SFSafeSymbols/SFSafeSymbols.git",
            .upToNextMajor(from: "5.3.0")
        )
    ],
    targets: [
        .target(
            name: "Conversation",
            dependencies: [
                .product(name: "Core", package: "Core"),
                .product(name: "Database", package: "Database"),
                .product(name: "Services", package: "Services"),
                .product(name: "XUI", package: "XUI"),
                .product(name: "ImageLoader", package: "ImageLoader"),
                .product(name: "VideoLoader", package: "ImageLoader"),
                .product(name: "MediaPicker", package: "MediaPicker"),
                .product(name: "SFSafeSymbols", package: "SFSafeSymbols")
            ],
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "ConversationTests",
            dependencies: [
                "Conversation",
                .product(name: "Database", package: "Database")
            ]
        )
    ]
)
