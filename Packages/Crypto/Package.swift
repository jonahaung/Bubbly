// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "Crypto",
	platforms: [.iOS(.v18)],
	products: [
		.library(
			name: "Crypto",
			targets: ["Crypto"]
		),
	],
	targets: [
		.target(
			name: "Crypto"
		),
		.testTarget(
			name: "CryptoTests",
			dependencies: ["Crypto"]
		),
	]
)
