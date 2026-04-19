// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "Services",
    platforms: [
        .iOS(.v26),
        .macOS(.v12)
    ],
    products: [
        .library(name: "BubblyWorkspace", targets: ["BubblyWorkspace"]) 
    ],
    dependencies: [
        .package(name: "Core", path: "Core"),
        .package(name: "Database", path: "Database"),
        .package(name: "Services", path: "Services"),
        .package(name: "Conversation", path: "Conversation"),
        .package(name: "BubblyContacts", path: "BubblyContacts"),
        .package(name: "Inbox", path: "Inbox"),
        .package(name: "Settings", path: "Settings"),
        .package(name: "MsgRoomMain", path: "MsgRoomMain")
    ],
    targets: [
        .target(
            name: "Services",
            dependencies: [
                .product(name: "Core", package: "Core"),
                .product(name: "Database", package: "Database"),
                .product(name: "Services", package: "Services"),
                .product(name: "Conversation", package: "Conversation"),
                .product(name: "BubblyContacts", package: "BubblyContacts"),
                .product(name: "Inbox", package: "Inbox"),
                .product(name: "Settings", package: "Settings"),
                .product(name: "MsgRoomMain", package: "MsgRoomMain")
            ]
        )
    ]
)
