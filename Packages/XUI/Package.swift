// swift-tools-version: 6.2

import PackageDescription

let package = Package(
	name: "XUI",
	platforms: [.iOS(.v26)],
	products: [
		.library(
			name: "XUI",
			targets: ["XUI"]
		),
	],
	dependencies: [
		.package(
			url: "https://github.com/SFSafeSymbols/SFSafeSymbols.git",
			.upToNextMajor(from: "5.3.0")
		),
		.package(url: "https://github.com/ordo-one/equatable.git", from: "1.2.0"),
	],
	targets: [
		.target(
			name: "XUI",
			dependencies: [
				.product(name: "SFSafeSymbols", package: "SFSafeSymbols"),
				.product(name: "Equatable", package: "equatable"),
			]
		),
		.testTarget(
			name: "XUITests",
			dependencies: ["XUI"]
		),
	]
)
