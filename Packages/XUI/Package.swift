// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "XUI",
    platforms: [
        .iOS(.v26),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "XUI",
            targets: ["XUI"]
        )
    ],
    dependencies: [
		.package(
			url: "https://github.com/SFSafeSymbols/SFSafeSymbols.git",
			.upToNextMajor(from: "5.3.0")
		),
		.package(url: "https://github.com/EmergeTools/Pow", from: "1.0.5"),
		.package(url: "https://github.com/tonyarnold/mockery.git", branch: "main")
    ],
    targets: [
        .target(
            name: "XUI",
            dependencies: [
                .product(name: "SFSafeSymbols", package: "SFSafeSymbols"),
				.product(name: "Pow", package: "Pow"),
				.product(name: "Mockery", package: "Mockery")
            ],
			resources: [
				.process("Resources")
			],
        ),
        .testTarget(
            name: "XUITests",
            dependencies: ["XUI"]
        )
    ]
)
