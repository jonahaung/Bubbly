// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MediaPicker",
    platforms: [.iOS(.v26)],
    products: [
        .library(
            name: "MediaPicker",
            targets: ["MediaPicker"]
        )
    ],
    targets: [
        .target(
            name: "MediaPicker"
        ),
        .testTarget(
            name: "MediaPickerTests",
            dependencies: ["MediaPicker"]
        )
    ]
)
