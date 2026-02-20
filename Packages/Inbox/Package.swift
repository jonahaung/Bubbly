// swift-tools-version: 6.2

import PackageDescription

let package = Package(
	name: "Inbox",
	platforms: [.iOS(.v26)],
	products: [
		.library(
			name: "Inbox",
			targets: ["Inbox"]
		),
	],
	dependencies: [
		.package(name: "Core", path: "../Core"),
		.package(name: "Database", path: "../Database"),
		.package(name: "Services", path: "../Services"),
	],
	targets: [
		.target(
			name: "Inbox",
			dependencies: [
				.product(name: "Core", package: "Core"),
				.product(name: "Database", package: "Database"),
				.product(name: "Services", package: "Services"),
			]
		),
		.testTarget(
			name: "InboxTests",
			dependencies: ["Inbox"]
		),
	]
)
