// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "Conversation",
    platforms: [
        .iOS(.v26)
    ],
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
        .package(name: "MediaPicker", path: "../MediaPicker")

    ],
    targets: [
        .target(
            name: "Conversation",
            dependencies: [
                .product(name: "Core", package: "Core", condition: .when(platforms: [.iOS])),
                .product(
                    name: "Database",
                    package: "Database",
                    condition: .when(platforms: [.iOS])
                ),
                .product(
                    name: "Services",
                    package: "Services",
                    condition: .when(platforms: [.iOS])
                ),
                .product(name: "XUI", package: "XUI", condition: .when(platforms: [.iOS])),
                .product(
                    name: "ImageLoader",
                    package: "ImageLoader",
                    condition: .when(platforms: [.iOS])
                ),
                .product(
                    name: "VideoLoader",
                    package: "ImageLoader",
                    condition: .when(platforms: [.iOS])
                ),
                .product(
                    name: "MediaPicker",
                    package: "MediaPicker",
                    condition: .when(platforms: [.iOS])
                )
            ],
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "ConversationTests",
            dependencies: [
                "Conversation"
            ]
        )
    ]
)
