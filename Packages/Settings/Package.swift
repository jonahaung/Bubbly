// swift-tools-version: 6.2

import PackageDescription

let package = Package(
	name: "Settings",
	platforms: [.iOS(.v26)],
	products: [
		.library(
			name: "Settings",
			targets: ["Settings"]
		),
	],
	dependencies: [
		.package(name: "Core", path: "../Core"),
		.package(name: "Database", path: "../Database"),
		.package(name: "Services", path: "../Services"),
		.package(name: "XUI", path: "../XUI"),
		.package(name: "ImageLoader", path: "../ImageLoader"),
	],
	targets: [
		.target(
			name: "Settings",
			dependencies: [
				.product(name: "Core", package: "Core"),
				.product(name: "Database", package: "Database"),
				.product(name: "Services", package: "Services"),
				.product(name: "XUI", package: "XUI"),
				.product(name: "ImageLoader", package: "ImageLoader"),
			]
		),
		.testTarget(
			name: "SettingsTests",
			dependencies: ["Settings"]
		),
	]
)
