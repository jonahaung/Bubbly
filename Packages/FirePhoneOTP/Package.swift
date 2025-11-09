// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FirePhoneOTP",
    platforms: [.iOS(.v17), .macOS(.v14), .tvOS(.v17)],
    products: [
        .library(
            name: "FirePhoneOTP",
            targets: ["FirePhoneOTP"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk", from: "12.4.0"),
        .package(url: "https://github.com/marmelroy/PhoneNumberKit", from: "3.7.0")
    ],
    targets: [
        .target(
            name: "FirePhoneOTP",
            dependencies: [
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "PhoneNumberKit", package: "PhoneNumberKit")
            ]
        ),
        .testTarget(
            name: "FirePhoneOTPTests",
            dependencies: ["FirePhoneOTP"]
        )
    ]
)
