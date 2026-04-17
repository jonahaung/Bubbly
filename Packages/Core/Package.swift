// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Core",
    platforms: [
        .iOS(.v26),
        .macOS(.v12),
    ],
    products: [
        .library(
            name: "Core",
            targets: ["Core"],
        ),
    ],
    dependencies: [
        .package(name: "XUI", path: "../XUI"),
        .package(name: "ImageLoader", path: "../ImageLoader"),
        .package(name: "Crypto", path: "../Crypto"),
        .package(name: "MediaPicker", path: "../MediaPicker"),
        .package(name: "FCM_V1", path: "../FCM_V1"),
        .package(url: "https://github.com/firebase/firebase-ios-sdk", from: "12.4.0"),
        .package(name: "FirePhoneOTP", path: "../FirePhoneOTP"),
    ],

    targets: [
        .target(
            name: "Core",
            dependencies: [
                .product(name: "XUI", package: "XUI"),
                .product(name: "FCM_V1", package: "FCM_V1"),
                .product(name: "ImageLoader", package: "ImageLoader"),
                .product(name: "VideoLoader", package: "ImageLoader"),
                .product(name: "MediaPicker", package: "MediaPicker"),
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseMessaging", package: "firebase-ios-sdk"),
                .product(name: "FirebaseStorage", package: "firebase-ios-sdk"),
                .product(name: "FirePhoneOTP", package: "FirePhoneOTP"),
                .product(name: "Crypto", package: "Crypto"),

            ],
            resources: [
                .process("Resources"),
            ],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency"),
            ],
        ),
        .testTarget(
            name: "CoreTests",
            dependencies: ["Core"],
        ),
    ],
)

