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
        .package(name: "Services", path: "../Services")
    ],
    targets: [
        .target(
            name: "Conversation",
            dependencies: [
                .product(name: "Services", package: "Services")
            ]
        ),
        .testTarget(
            name: "ConversationTests",
            dependencies: [
                "Conversation"
            ]
        ),
    ]
)
